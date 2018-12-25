import AsyncAwait
import UIKit

protocol PlanControlling {
    func setDelegate(_ delegate: PlanControllerDelegate)
}

protocol PlanControllerDelegate: AnyObject {
    func controller(_ controller: PlanController, openItemDetailWithItem item: TodoItem, sender: UIViewController)
}

final class PlanController: PlanControlling {
    private let viewController: PlanViewControlling
    private let alertController: AlertControlling
    private let repository: PlanRepositoring
    private let badge: Badge
    private weak var delegate: PlanControllerDelegate?

    init(viewController: PlanViewControlling, alertController: AlertControlling, repository: PlanRepositoring,
         badge: Badge) {
        self.viewController = viewController
        self.alertController = alertController
        self.repository = repository
        self.badge = badge
    }

    func setDelegate(_ delegate: PlanControllerDelegate) {
        self.delegate = delegate
    }

    // MARK: - private

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterForeground(_:)),
                                               name: .UIApplicationWillEnterForeground, object: nil)
    }

    private func tearDownNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
    }

    @objc
    private func applicationDidEnterForeground(_ notification: Notification) {
        reload()
    }

    private func reload() {
        async({
            let sections = [
                PlanSection.today: try await(self.repository.fetchTodayItems()),
                PlanSection.missed: try await(self.repository.fetchMissedItems()),
                PlanSection.later: try await(self.repository.fetchLaterItems())
            ]
            let viewState = self.viewController.viewState?.copy(sections: sections) ?? PlanViewState(
                sections: sections,
                isTableHeaderAnimating: false
            )
            self.viewController.viewState = viewState
            self.badge.number = (viewState.totalMissed + viewState.totalToday)
        }, onError: { error in
            self.alertController.showAlert(.dataError(error))
        })
    }
}

// MARK: - PlanViewControllerDelegate

extension PlanController: PlanViewControllerDelegate {
    func viewControllerWillAppear(_ viewController: PlanViewController) {
        setupNotifications()
        viewController.viewState = viewController.viewState?.copy(isTableHeaderAnimating: true)
    }

    func viewControllerWillDisappear(_ viewController: PlanViewController) {
        tearDownNotifications()
        viewController.viewState = viewController.viewState?.copy(isTableHeaderAnimating: false)
    }

    func viewController(_ viewController: PlanViewController, performAction action: PlanAction) {
        switch action {
        case .add:
            switch repository.newItem() {
            case .success(let item):
                delegate?.controller(self, openItemDetailWithItem: item, sender: viewController)
            case .failure(let error):
                alertController.showAlert(.dataError(error))
            }
        }
    }

    func viewController(_ viewController: PlanViewController, didSelectItem item: TodoItem) {
        delegate?.controller(self, openItemDetailWithItem: item, sender: viewController)
    }

    func viewController(_ viewController: PlanViewController, performAction action: PlanItemAction,
                        onItem item: TodoItem) {
        async({
            switch action {
            case .delete: _ = try await(self.repository.delete(item: item))
            case .done: _ = try await(self.repository.done(item: item))
            case .later: _ = try await(self.repository.later(item: item))
            case .split: _ = try await(self.repository.split(item: item))
            }
        }, onError: { error in
            self.alertController.showAlert(.dataError(error))
        })
    }
}
