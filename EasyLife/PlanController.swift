import AsyncAwait
import UIKit

protocol PlanControlling {
    func start()
    func setDelegate(_ delegate: PlanControllerDelegate)
}

protocol PlanControllerDelegate: AnyObject {
    func controller(_ controller: PlanController, didSelectItem item: TodoItem, sender: Segueable)
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

        viewController.setDelegate(self)
    }

    func start() {
        viewController.viewState = PlanViewState(sections: [:])
        viewController.setTableHeaderAnimation(RainbowAnimation())
        reload()
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
            let isAnimating = sections.reduce(0) { $0 + $1.value.count } > 0
            onMain {
                self.viewController.setIsTableHeaderAnimating(isAnimating)
                guard let viewState = self.viewController.viewState else { return }
                self.viewController.viewState = viewState.copy(sections: sections)
                self.badge.number = (viewState.totalMissed + viewState.totalToday)
            }
        }, onError: { error in
            self.alertController.showAlert(.dataError(error))
        })
    }

    private func addNewItem() {
        switch repository.newItem() {
        case .success(let item):
            delegate?.controller(self, didSelectItem: item, sender: viewController)
        case .failure(let error):
            alertController.showAlert(.dataError(error))
        }
    }
}

// MARK: - PlanViewControllerDelegate

extension PlanController: PlanViewControllerDelegate {
    func viewControllerWillAppear(_ viewController: PlanViewControlling) {
        setupNotifications()
        reload()
    }

    func viewControllerWillDisappear(_ viewController: PlanViewControlling) {
        tearDownNotifications()
        viewController.setIsTableHeaderAnimating(false)
    }

    func viewController(_ viewController: PlanViewControlling, performAction action: PlanAction) {
        switch action {
        case .add: addNewItem()
        }
    }

    func viewController(_ viewController: PlanViewControlling, didSelectItem item: TodoItem) {
        delegate?.controller(self, didSelectItem: item, sender: viewController)
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
            self.alertController.showAlert(.dataError(error))
        })
    }
}
