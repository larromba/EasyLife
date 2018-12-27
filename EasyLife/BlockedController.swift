import Foundation

protocol BlockedControlling {
    func setViewController(_ viewController: BlockedViewControlling)
}

final class BlockedController: BlockedControlling {
    private var viewController: BlockedViewControlling?

    func setViewController(_ viewController: BlockedViewControlling) {
        self.viewController = viewController
    }
}
