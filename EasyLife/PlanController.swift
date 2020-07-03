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
}

final class PlanController: PlanControlling {
    private let viewController: PlanViewControlling
    private let alertController: AlertControlling
    private let repository: PlanRepositoring
    private let badge: Badging
    private weak var delegate: PlanControllerDelegate?
    private var router: StoryboardRouting?

    init(viewController: PlanViewControlling, alertController: AlertControlling, repository: PlanRepositoring,
         badge: Badging) {
        self.viewController = viewController
        self.alertController = alertController
        self.repository = repository
        self.badge = badge

        viewController.setDelegate(self)
    }

    func start() {
        viewController.viewState = PlanViewState(sections: [:], isDoneHidden: true)
        viewController.setTableHeaderAnimation(RainbowAnimation())
        reload()
    }

    func setDelegate(_ delegate: PlanControllerDelegate) {
        self.delegate = delegate
    }

    func setRouter(_ router: StoryboardRouting) {
        self.router = router
    }

    func openNewTodoItem() {
        viewController(viewController, performAction: .add)
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
        guard let viewState = self.viewController.viewState else { return }
        async({
            let sections = [
                PlanSection.today: try await(self.repository.fetchTodayItems()),
                PlanSection.missed: try await(self.repository.fetchMissedItems()),
                PlanSection.later: try await(self.repository.fetchLaterItems())
            ]
            let newViewState = viewState.copy(sections: sections, isDoneHidden: false)
            _ = try? await(self.badge.setNumber(newViewState.totalMissed + newViewState.totalToday))
            onMain {
                self.viewController.viewState = newViewState
                self.viewController.setIsTableHeaderAnimating(!newViewState.isTableHeaderHidden)
            }
        }, onError: { error in
            onMain { self.alertController.showAlert(Alert(error: error)) }
        })
    }

    private func handleLongPressAction(_ action: PlanItemLongPressAction, forItem item: TodoItem) {
        async({
            switch action {
            case .doToday: try await(self.repository.makeToday(item: item))
            case .doTomorrow: try await(self.repository.makeTomorrow(item: item))
            case .moveAllToday(let items): try await(self.repository.makeAllToday(items: items))
            case .moveAllTomorrow(let items): try await(self.repository.makeAllTomorrow(items: items))
            }
            self.reload()
        }, onError: { error in
            onMain { self.alertController.showAlert(Alert(error: error)) }
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
        case .add: delegate?.controller(self, handleContext: repository.newItemContext(), sender: viewController)
        }
    }

    func viewController(_ viewController: PlanViewControlling, prepareForSegue segue: UIStoryboardSegue) {
        router?.handleSegue(segue)
    }

    func viewController(_ viewController: PlanViewControlling, didSelectItem item: TodoItem) {
        delegate?.controller(self, handleContext: repository.existingItemContext(item: item), sender: viewController)
    }

    func viewController(_ viewController: PlanViewControlling, performAction action: PlanItemAction,
                        onItem item: TodoItem) {
        async({
            switch action {
            case .delete: _ = try await(self.repository.delete(item: item))
            case .done: _ = try await(self.repository.done(item: item))
            case .later: _ = try await(self.repository.later(item: item))
            case .split: _ = try await(self.repository.split(item: item))
            }
            self.reload()
        }, onError: { error in
            onMain { self.alertController.showAlert(Alert(error: error)) }
        })
    }

    func viewController(_ viewController: PlanViewControlling, handleActions actions: [PlanItemLongPressAction],
                        onItem item: TodoItem) {
        let cancelAction = Alert.Action(title: L10n.planItemLongPressActionCancel, handler: nil)
        let actions = actions.map { action in
            Alert.Action(title: action.title, handler: { self.handleLongPressAction(action, forItem: item) })
        }
        let alert = Alert(title: L10n.planItemLongPressActionTitle, message: "", cancel: cancelAction, actions: actions,
                          textField: nil)
        alertController.showAlert(alert)
    }
}
