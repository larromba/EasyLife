import AsyncAwait
import AVFoundation
import Foundation
import UIKit

// sourcery: name = FocusController
protocol FocusControlling: AnyObject, Mockable {
    func setViewController(_ viewController: FocusViewControlling)
    func setAlertController(_ alertController: AlertControlling)
    func setDelegate(_ delegate: FocusControllerDelegate)
}

protocol FocusControllerDelegate: AnyObject {
    func controllerFinished(_ controller: FocusControlling)
}

final class FocusController: FocusControlling {
    private let repository: FocusRepositoring
    private let alarm: Alarming
    private weak var viewController: FocusViewControlling?
    private var alertController: AlertControlling?
    private weak var delegate: FocusControllerDelegate?
    private var timer: Timer?

    init(repository: FocusRepositoring, alarm: Alarming) {
        self.repository = repository
        self.alarm = alarm
    }

    func setViewController(_ viewController: FocusViewControlling) {
        self.viewController = viewController
        viewController.setDelegate(self)
        reload()
    }

    func setAlertController(_ alertController: AlertControlling) {
        self.alertController = alertController
    }

    func setDelegate(_ delegate: FocusControllerDelegate) {
        self.delegate = delegate
    }

    // MARK: - private

    private func reload() {
        async({
            // items must not be blocked by items in other sections
            // if so, show an alert
            let missingItems = try await(self.repository.fetchMissingItems())
            guard missingItems.isEmpty else {
                onMain { self.showUnfocusableAlert() }
                return
            }
            // ensure first item can be done, else it's recursively blocked.
            // nothing can be done if:
            // a blocks b
            // b blocks c
            // c blocks a
            guard try await(self.repository.isDoable()) else {
                onMain { self.showRecursivelyBlockedAlert() }
                return
            }
            // items are presented one at a time, so if no more items, finish
            let items = try await(self.repository.fetchItems())
            guard !items.isEmpty else {
                onMain { self.close() }
                return
            }
            onMain {
                self.viewController?.viewState = FocusViewState(
                    items: items,
                    backgroundColor: .black,
                    timerButtonViewState: TimerButtonViewState(action: .start),
                    focusTime: .none
                )
                self.viewController?.flashTableView()
                self.viewController?.reloadTableViewData()
            }
        }, onError: { error in
            onMain { self.alertController?.showAlert(Alert(error: error)) }
        })
    }

    private func showUnfocusableAlert() {
        let cancelAction = Alert.Action(title: L10n.unfocusableAlertNo, handler: {
            self.delegate?.controllerFinished(self)
        })
        let confirmAction = Alert.Action(title: L10n.unfocusableAlertYes, handler: {
            self.moveMissingItems()
        })
        let alert = Alert(title: L10n.unfocusableAlertTitle,
                          message: L10n.unfocusableAlertMessage,
                          cancel: cancelAction,
                          actions: [confirmAction],
                          textField: nil)
        alertController?.showAlert(alert)
    }

    private func showRecursivelyBlockedAlert() {
        let cancelAction = Alert.Action(title: L10n.recursivelyBlockedAlertOk, handler: {
            self.delegate?.controllerFinished(self)
        })
        let alert = Alert(title: L10n.recursivelyBlockedAlertTitle,
                          message: L10n.recursivelyBlockedAlertMessage,
                          cancel: cancelAction,
                          actions: [],
                          textField: nil)
        alertController?.showAlert(alert)
    }

    private func moveMissingItems() {
        async({
            let missingItems = try await(self.repository.fetchMissingItems())
            try missingItems.forEach { try await(self.repository.today(item: $0)) }
            self.reload()
        }, onError: { error in
            onMain { self.alertController?.showAlert(Alert(error: error)) }
        })
    }

    private func openPicker() {
        viewController?.viewState?.focusTime = .default
        viewController?.openDatePicker()
    }

    private func closePicker() {
        viewController?.viewState?.focusTime = .none
        viewController?.closeDatePicker()
    }

    private func startTimer() {
        viewController?.viewState = viewController?.viewState?.copy(
            backgroundColor: .darkGray,
            timerButtonViewState: TimerButtonViewState(action: .stop)
        )
        viewController?.closeDatePicker()
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerTick), userInfo: nil,
                                     repeats: true)
    }

    private func stopTimer() {
        timer?.invalidate()
        alarm.stop()
        viewController?.viewState = viewController?.viewState?.copy(
            backgroundColor: .black,
            timerButtonViewState: TimerButtonViewState(action: .start)
        )
        viewController?.viewState?.focusTime = .none
    }

    private func fireAlarm() {
        timer?.invalidate()
        alarm.start()
        timer = Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(backgroundChangeTick),
                                     userInfo: nil, repeats: true)
    }

    private func close() {
        stopAllProcesses()
        delegate?.controllerFinished(self)
    }

    private func stopAllProcesses() {
        timer?.invalidate()
        alarm.stop()
    }

    // MARK: - ticks

    @objc
    private func timerTick() {
        guard let viewState = viewController?.viewState else { return }
        let newValue = viewState.focusTime.timeValue() - 1.0
        viewController?.viewState?.focusTime = .custom(newValue)
        guard newValue > 0 else {
            fireAlarm()
            return
        }
    }

    @objc
    private func backgroundChangeTick() {
        guard let viewState = viewController?.viewState else { return }
        let color: UIColor = (viewState.backgroundColor == .darkGray) ? .red : .darkGray
        viewController?.viewState = viewState.copy(backgroundColor: color)
    }
}

// MARK: - FocusViewControllerDelegate

extension FocusController: FocusViewControllerDelegate {
    func viewController(_ viewController: FocusViewControlling, performAction action: FocusAction) {
        switch action {
        case .close: close()
        case .openPicker: openPicker()
        case .closePicker: closePicker()
        case .startTimer: startTimer()
        case .stopTimer: stopTimer()
        }
    }

    func viewController(_ viewController: FocusViewControlling, performAction action: FocusItemAction,
                        onItem item: TodoItem, at indexPath: IndexPath) {
        async({
            switch action {
            case .done: _ = try await(self.repository.done(item: item))
            }
            self.reload()
        }, onError: { error in
            onMain { self.alertController?.showAlert(Alert(error: error)) }
        })
    }
}
