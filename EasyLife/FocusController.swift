import AsyncAwait
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
    private weak var viewController: FocusViewControlling?
    private var alertController: AlertControlling?
    private weak var delegate: FocusControllerDelegate?

    init(repository: FocusRepositoring) {
        self.repository = repository
    }

    func setViewController(_ viewController: FocusViewControlling) {
        self.viewController = viewController
        viewController.setDelegate(self)
//        viewController.viewState = FocusViewState(sections: [:], isEditing: false)
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
//        async({
//            let prioritizedProjects = try await(self.repository.fetchPrioritizedProjects())
//            let otherProjects = try await(self.repository.fetchOtherProjects())
//            let sections = [
//                ProjectSection.prioritized: prioritizedProjects,
//                ProjectSection.other: otherProjects
//            ]
//            onMain {
//                self.viewController?.viewState = self.viewController?.viewState?.copy(sections: sections)
//            }
//        }, onError: { error in
//            self.alertController?.showAlert(Alert(error: error))
//        })
    }

//    private func toggleEditTable() {
//        guard let viewState = viewController?.viewState else { return }
//        viewController?.viewState = viewState.copy(isEditing: !viewState.isEditing)
//    }
}

// MARK: - FocusViewControllerDelegate

extension FocusController: FocusViewControllerDelegate {
    func viewController(_ viewController: FocusViewControlling, performAction action: FocusAction) {
        switch action {
        case .close: delegate?.controllerFinished(self)
        }
    }

    func viewController(_ viewController: FocusViewControlling, moveRowAt sourceIndexPath: IndexPath,
                        to destinationIndexPath: IndexPath) {
//        async({
//            guard
//                let viewState = viewController.viewState,
//                let sourceSection = FocusSection(rawValue: sourceIndexPath.section),
//                let sourceProject = viewState.project(at: sourceIndexPath),
//                let destinationSection = FocusSection(rawValue: destinationIndexPath.section),
//                let destinationProject = viewState.project(at: destinationIndexPath) else {
//                    return
//            }
//            if sourceSection == .prioritized, destinationSection == .other {
//                _ = try await(self.repository.deprioritize(project: sourceProject))
//            } else if sourceSection == .prioritized && destinationSection == .prioritized {
//                if sourceIndexPath.row < destinationIndexPath.row {
//                    _ = try await(self.repository.prioritise(sourceProject, below: destinationProject))
//                } else if sourceIndexPath.row > destinationIndexPath.row {
//                    _ = try await(self.repository.prioritise(sourceProject, above: destinationProject))
//                }
//            } else if sourceSection == .other && destinationSection == .prioritized {
//                _ = try await(self.repository.prioritize(project: sourceProject, max: viewState.maxPriorityItems))
//            }
//            self.reload()
//        }, onError: { error in
//            self.alertController?.showAlert(Alert(error: error))
//        })
    }
}
