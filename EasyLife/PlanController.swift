import AsyncAwait
import UIKit

// sourcery: name = PlanController
protocol PlanControlling: Mockable {
    func start()
    func setDelegate(_ delegate: PlanControllerDelegate)
    func openNewTodoItem()
    func openFocusWithDate(_ date: Date)
}

protocol PlanControllerDelegate: AnyObject {
    func controller(_ controller: PlanControlling, handleContext context: TodoItemContext, sender: Segueable)
    func controller(_ controller: PlanControlling, showAlert alert: Alert)
    func controller(_ controller: PlanControlling, handleSegue segue: UIStoryboardSegue, sender: Any?)
    func controllerRequestsHoliday(_ controller: PlanControlling)
    func controllerRequestsFocus(_ controller: PlanControlling, withDate date: Date, sender: Segueable)
}

final class PlanController: PlanControlling {
    private let planRepository: PlanRepositoring
    private let holidayRepository: HolidayRepositoring
    private let badge: Badge
    private weak var viewController: PlanViewControlling?
    private weak var delegate: PlanControllerDelegate?
    private var isReloading = false
    private let notificationCenter: NotificationCenter

    init(viewController: PlanViewControlling, planRepository: PlanRepositoring, holidayRepository: HolidayRepositoring,
         badge: Badge, notificationCenter: NotificationCenter = .default) {
        self.viewController = viewController
        self.planRepository = planRepository
        self.holidayRepository = holidayRepository
        self.badge = badge
        self.notificationCenter = notificationCenter
        viewController.setDelegate(self)
    }

    func start() {
        viewController?.viewState = PlanViewState(sections: [:], isDoneHidden: true)
        viewController?.setTableHeaderAnimation(RainbowAnimation())
        guard !holidayRepository.isEnabled else {
            delegate?.controllerRequestsHoliday(self)
            return
        }
        reload()
    }

    func setDelegate(_ delegate: PlanControllerDelegate) {
        self.delegate = delegate
    }

    func openNewTodoItem() {
        guard let viewController = viewController else { return }
        self.viewController(viewController, performAction: .add)
    }

    func openFocusWithDate(_ date: Date) {
        guard let viewController = viewController else { return }
        delegate?.controllerRequestsFocus(self, withDate: date, sender: viewController)
    }

    // MARK: - private

    private func setupNotifications() {
        notificationCenter.addObserver(self, selector: #selector(applicationDidEnterForeground(_:)),
                                       name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    private func tearDownNotifications() {
        notificationCenter.removeObserver(self, name: UIApplication.didBecomeActiveNotification,
                                          object: nil)
    }

    @objc
    private func applicationDidEnterForeground(_ notification: Notification) {
        reload()
    }

    private func reload() {
        guard let viewState = self.viewController?.viewState, !isReloading else { return }
        isReloading = true
        async({
            let sections = [
                PlanSection.today: try await(self.planRepository.fetchTodayItems()),
                PlanSection.missed: try await(self.planRepository.fetchMissedItems()),
                PlanSection.later: try await(self.planRepository.fetchLaterItems())
            ]
            let newViewState = viewState.copy(sections: sections, isDoneHidden: false)
            _ = try? await(self.badge.setNumber(newViewState.totalMissed + newViewState.totalToday))
            onMain {
                self.viewController?.viewState = newViewState
                self.viewController?.setIsTableHeaderAnimating(!newViewState.isTableHeaderHidden)
                self.viewController?.reload()
                self.isReloading = false
            }
        }, onError: { error in
            onMain { self.delegate?.controller(self, showAlert: Alert(error: error)) }
            self.isReloading = false
        })
    }

    private func handleLongPressAction(_ action: PlanItemLongPressAction, forItem item: TodoItem) {
        async({
            switch action {
            case .doToday: try await(self.planRepository.makeToday(item: item))
            case .doTomorrow: try await(self.planRepository.makeTomorrow(item: item))
            case .moveAllToday(let items): try await(self.planRepository.makeAllToday(items: items))
            case .moveAllTomorrow(let items): try await(self.planRepository.makeAllTomorrow(items: items))
            }
            self.reload()
        }, onError: { error in
            onMain { self.delegate?.controller(self, showAlert: Alert(error: error)) }
        })
    }
}

// MARK: - PlanViewControllerDelegate

extension PlanController: PlanViewControllerDelegate {
    func viewController(_ viewController: PlanViewControlling, handleViewAction viewAction: ViewAction) {
        switch viewAction {
        case .willAppear:
            setupNotifications()
            reload()
        case .willDisappear:
            tearDownNotifications()
            viewController.setIsTableHeaderAnimating(false)
        }
    }

    func viewController(_ viewController: PlanViewControlling, performAction action: PlanAction) {
        switch action {
        case .add: delegate?.controller(self, handleContext: planRepository.newItemContext(), sender: viewController)
        case .holiday: delegate?.controllerRequestsHoliday(self)
        }
    }

    func viewController(_ viewController: PlanViewControlling, prepareForSegue segue: UIStoryboardSegue, sender: Any?) {
        delegate?.controller(self, handleSegue: segue, sender: sender)
    }

    func viewController(_ viewController: PlanViewControlling, didSelectItem item: TodoItem) {
        delegate?.controller(self, handleContext: planRepository.existingItemContext(item: item),
                             sender: viewController)
    }

    func viewController(_ viewController: PlanViewControlling, performAction action: PlanItemAction,
                        onItem item: TodoItem) {
        async({
            switch action {
            case .delete: _ = try await(self.planRepository.delete(item: item))
            case .done: _ = try await(self.planRepository.done(item: item))
            case .later: _ = try await(self.planRepository.later(item: item))
            case .split: _ = try await(self.planRepository.split(item: item))
            }
            self.reload()
        }, onError: { error in
            onMain { self.delegate?.controller(self, showAlert: Alert(error: error)) }
        })
    }

    func viewController(_ viewController: PlanViewControlling, handleActions actions: [PlanItemLongPressAction],
                        onItem item: TodoItem) {
        let cancelAction = Alert.Action(title: L10n.planItemLongPressActionCancel, handler: nil)
        let actions = actions.map { action in
            Alert.Action(title: action.title, handler: { self.handleLongPressAction(action, forItem: item) })
        }
        delegate?.controller(self, showAlert: Alert(
            title: L10n.planItemLongPressActionTitle,
            message: "",
            cancel: cancelAction,
            actions: actions,
            textField: nil
        ))
    }
}
