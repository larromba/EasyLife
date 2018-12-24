import Foundation

protocol ItemDetailControlling {

}

final class ItemDetailController: ItemDetailControlling {
    private let viewController: ItemDetailViewControlling
    private let repository: ItemDetailRepositoring

    init(viewController: ItemDetailViewControlling, repository: ItemDetailRepositoring) {
        self.viewController = viewController
        self.repository = repository
    }

/*
     _ = self.navigationController?.popViewController(animated: true)
     _ = self.navigationController?.popViewController(animated: true)

     //save
     item.name = name
     item.notes = notes
     item.date = date
     item.repeatState = repeatState
     item.project = project

     blockable?.forEach({ blockedItem in
     if blockedItem.isBlocked {
     item.addToBlockedBy(blockedItem.item)
     } else {
     item.removeFromBlockedBy(blockedItem.item)
     }
     })
     */
}

// MARK: - ItemDetailViewControllerDelegate

extension ItemDetailController: ItemDetailViewControllerDelegate {
    func viewController(_ viewController: ItemDetailViewControlling, performAction action: ItemDetailAction) {
        // TODO: this
    }

    func viewController(_ viewController: ItemDetailViewControlling, updatedState state: ItemDetailViewState) {
        // TODO: this
    }
}
