import AsyncAwait
import UIKit

// sourcery: name = PlanController
protocol PlanControlling: Mockable {
    func start()
    func setDelegate(_ delegate: PlanControllerDelegate)
    func setRouter(_ router: StoryboardRouting)
    func openNewTodoItem()
}

protocol PlanControllerDelegate: AnyObject {
    func controller(_ controller: PlanControlling, handleContext context: TodoItemContext, sender: Segueable)
    func controller(_ controller: PlanControlling, showAlert alert: Alert)
    func controllerRequestsHoliday(_ controller: PlanControlling)
}

final class PlanController: PlanControlling {
    private let planRepository: PlanRepositoring
    private let holidayRepository: HolidayRepositoring
    private let badge: Badge
    private weak var viewController: PlanViewControlling?
    private weak var delegate: PlanControllerDelegate?
    private weak var router: StoryboardRouting?
    private var isReloading = false

    init(viewController: PlanViewControlling, planRepository: PlanRepositoring,
         holidayRepository: HolidayRepositoring, badge: Badge) {
        self.viewController = viewController
        self.planRepository = planRepository
        self.holidayRepository = holidayRepository
        self.badge = badge
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

    func setRouter(_ router: StoryboardRouting) {
        self.router = router
    }

    func openNewTodoItem() {
        guard let viewController = viewController else { return }
        self.viewController(viewController, performAction: .add)
    }

    // MARK: - private

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterForeground(_:)),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    private func tearDownNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification,
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

    func viewController(_ viewController: PlanViewControlling, prepareForSegue segue: UIStoryboardSegue) {
        router?.handleSegue(segue)
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
