import AsyncAwait
import AVFoundation
import Foundation
import UIKit

// sourcery: name = FocusController
protocol FocusControlling: AnyObject, Mockable {
    func setViewController(_ viewController: FocusViewControlling)
    func setDelegate(_ delegate: FocusControllerDelegate)
    func setTriggerDate(_ date: Date)
    func start()
}

protocol FocusControllerDelegate: AnyObject {
    func controllerFinished(_ controller: FocusControlling)
    func controller(_ controller: FocusControlling, showAlert alert: Alert)
}

final class FocusController: FocusControlling {
    private let repository: FocusRepositoring
    private let alarm: Alarming
    private let appClosedTimer: AppClosedTiming
    private let alarmNotificationHandler: AlarmNotificationHandling
    private var timer: Timer?
    private var triggerDate: Date?
    private weak var viewController: FocusViewControlling?
    private weak var delegate: FocusControllerDelegate?

    init(repository: FocusRepositoring, alarm: Alarming, appClosedTimer: AppClosedTiming = AppClosedTimer(),
         alarmNotificationHandler: AlarmNotificationHandling) {
        self.repository = repository
        self.alarm = alarm
        self.appClosedTimer = appClosedTimer
        self.alarmNotificationHandler = alarmNotificationHandler
        appClosedTimer.setDelegate(self)
    }

    func setViewController(_ viewController: FocusViewControlling) {
        self.viewController = viewController
        viewController.setDelegate(self)
    }

    func setDelegate(_ delegate: FocusControllerDelegate) {
        self.delegate = delegate
    }

    func setTriggerDate(_ date: Date) {
        triggerDate = date
    }

    func start() {
        reload()
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
                if let triggerDate = self.triggerDate {
                    self.viewController?.viewState = FocusViewState(
                        items: items,
                        backgroundColor: .black,
                        timerButtonViewState: TimerButtonViewState(action: .start),
                        focusTime: .custom(triggerDate.timeIntervalSinceNow)
                    )
                    self.startLocalTimer()
                } else {
                    self.viewController?.viewState = FocusViewState(
                        items: items,
                        backgroundColor: .black,
                        timerButtonViewState: TimerButtonViewState(action: .start),
                        focusTime: .none
                    )
                }
                self.viewController?.flashTableView()
                self.viewController?.reloadTableViewData()
            }
        }, onError: { error in
            onMain { self.delegate?.controller(self, showAlert: Alert(error: error)) }
        })
    }

    private func showUnfocusableAlert() {
        let cancelAction = Alert.Action(title: L10n.unfocusableAlertNo, handler: {
            self.close()
        })
        let confirmAction = Alert.Action(title: L10n.unfocusableAlertYes, handler: {
            self.moveMissingItems()
        })
        let alert = Alert(title: L10n.unfocusableAlertTitle,
                          message: L10n.unfocusableAlertMessage,
                          cancel: cancelAction,
                          actions: [confirmAction],
                          textField: nil)
        delegate?.controller(self, showAlert: alert)
    }

    private func showRecursivelyBlockedAlert() {
        let cancelAction = Alert.Action(title: L10n.recursivelyBlockedAlertOk, handler: {
            self.close()
        })
        let alert = Alert(title: L10n.recursivelyBlockedAlertTitle,
                          message: L10n.recursivelyBlockedAlertMessage,
                          cancel: cancelAction,
                          actions: [],
                          textField: nil)
        delegate?.controller(self, showAlert: alert)
    }

    private func showTimesUpAlert() {
        let alert = Alert(title: L10n.recursivelyBlockedAlertTitle,
                          message: L10n.recursivelyBlockedAlertMessage,
                          cancel: Alert.Action(title: L10n.recursivelyBlockedAlertOk, handler: nil),
                          actions: [],
                          textField: nil)
        delegate?.controller(self, showAlert: alert)
    }

    private func moveMissingItems() {
        async({
            let missingItems = try await(self.repository.fetchMissingItems())
            try missingItems.forEach { try await(self.repository.today(item: $0)) }
            self.reload()
        }, onError: { error in
            onMain { self.delegate?.controller(self, showAlert: Alert(error: error)) }
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

    private func startLocalTimer() {
        viewController?.viewState = viewController?.viewState?.copy(
            backgroundColor: .darkGray,
            timerButtonViewState: TimerButtonViewState(action: .stop)
        )
        viewController?.closeDatePicker()
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerTick), userInfo: nil,
                                     repeats: true)
    }

    private func startTimer() {
        startLocalTimer()
        alarmNotificationHandler.start(in: viewController?.viewState?.focusTime.timeValue() ?? 0)
    }

    private func stopTimer() {
        stopAllProcesses()
        viewController?.viewState = viewController?.viewState?.copy(
            backgroundColor: .black,
            timerButtonViewState: TimerButtonViewState(action: .start)
        )
        viewController?.viewState?.focusTime = .none
    }

    private func fireAlarm() {
        stopAllProcesses()
        alarm.start()
        timer = Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(backgroundChange),
                                     userInfo: nil, repeats: true)
    }

    private func close() {
        stopAllProcesses()
        delegate?.controllerFinished(self)
    }

    private func stopAllProcesses() {
        triggerDate = nil
        timer?.invalidate()
        alarm.stop()
        alarmNotificationHandler.stop()
    }

    // MARK: - timer action

    @objc
    private func timerTick() {
        guard var viewState = viewController?.viewState else { return }
        viewState.focusTime -= 1.0
        viewController?.viewState = viewState
        guard viewState.focusTime > 0 else {
            fireAlarm()
            return
        }
    }

    @objc
    private func backgroundChange() {
        guard let viewState = viewController?.viewState else { return }
        let color: UIColor = (viewState.backgroundColor == .darkGray) ? .red : .darkGray
        viewController?.viewState = viewState.copy(backgroundColor: color)
    }
}

// MARK: - FocusViewControllerDelegate

extension FocusController: FocusViewControllerDelegate {
    func viewController(_ viewController: FocusViewControlling, handleViewAction viewAction: ViewAction) {
        switch viewAction {
        case .willAppear: appClosedTimer.startListening()
        case .willDisappear: appClosedTimer.stopListening()
        }
    }

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
            case .done:
                onMain { self.stopTimer() }
                _ = try await(self.repository.done(item: item))
            }
            self.reload()
        }, onError: { error in
            onMain { self.delegate?.controller(self, showAlert: Alert(error: error)) }
        })
    }
}

// MARK: - AppClosedTimerDelegate

extension FocusController: AppClosedTimerDelegate {
    func timer(_ timer: AppClosedTiming, isReopenedAfterTime time: TimeInterval) {
        guard var viewState = viewController?.viewState,
            viewState.timerButtonViewState.action == .stop else { return }
        guard time < viewState.focusTime else {
            viewController?.viewState?.focusTime = .none
            self.fireAlarm()
            return
        }
        viewState.focusTime -= time
        viewController?.viewState = viewState
    }
}
