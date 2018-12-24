import AsyncAwait
import Foundation
import UIKit

protocol ProjectsControlling: AnyObject {
    func setViewController(_ viewController: ProjectsViewControlling)
    func setDelegate(_ delegate: ProjectsControllerDelegate)
}

protocol ProjectsControllerDelegate: AnyObject {
    func controllerFinished(_ controller: ProjectsController)
}

final class ProjectsController: ProjectsControlling {
    private struct EditContext {
        var project: Project
    }

    private let alertController: AlertControlling
    private let repository: ProjectsRepositoring
    private var viewController: ProjectsViewControlling?
    private weak var delegate: ProjectsControllerDelegate?

    init(alertController: AlertControlling, repository: ProjectsRepositoring) {
        self.alertController = alertController
        self.repository = repository
    }

    func setViewController(_ viewController: ProjectsViewControlling) {
        self.viewController = viewController
    }

    func setDelegate(_ delegate: ProjectsControllerDelegate) {
        self.delegate = delegate
    }

    private func addProject() {
        var editableName: String?
        let action = Alert.Action(title: L10n.newProjectAlertOk, handler: {
            // TODO: this
            async({
                _ = try await(self.repository.addProject(name: editableName!)) // TODO: bang
                let sections = try await(self.repository.load())
                self.viewController?.viewState = self.viewController?.viewState?.copy(sections: sections)
            }, onError: { _ in
                // TODO: handle
            })
        })
        let textField = Alert.TextField(placeholder: L10n.newProjectAlertName, text: "", handler: { text in
            editableName = text
        })
        let alert = Alert(title: L10n.newProjectAlertTitle,
                          message: "",
                          cancel: Alert.Action(title: L10n.newProjectAlertCancel, handler: nil),
                          actions: [action],
                          textField: textField)
        alertController.showAlert(alert)
    }

    private func editProject(_ project: Project) {
        var editableName = project.name
        let action = Alert.Action(title: L10n.editProjectAlertOk, handler: {
            // TODO: this
            async({
                _ = try await(self.repository.updateName(name: editableName!, for: project)) // TODO: bang
                let sections = try await(self.repository.load())
                self.viewController?.viewState = self.viewController?.viewState?.copy(sections: sections)
            }, onError: { _ in
                // TODO: handle
            })
        })
        let textField = Alert.TextField(placeholder: L10n.editProjectAlertName, text: project.name, handler: { text in
            editableName = text
            //alertController.actions[1].isEnabled = (textField.text?.isEmpty == false) // TODO: this
        })
        let alert = Alert(title: L10n.editProjectAlertTitle,
                          message: "",
                          cancel: Alert.Action(title: L10n.editProjectAlertCancel, handler: nil),
                          actions: [action],
                          textField: textField)
        alertController.showAlert(alert)
    }
}

// MARK: - ProjectsViewControllerDelegate

extension ProjectsController: ProjectsViewControllerDelegate {
    func viewController(_ viewController: ProjectsViewController, performAction action: ProjectsAction) {
        switch action {
        case .add:
            addProject()
        case .edit(let project):
            editProject(project)
        case .done:
            delegate?.controllerFinished(self)
        }
    }

    func viewController(_ viewController: ProjectsViewController, performAction action: ProjectItemAction,
                        forProject project: Project) {
        guard let viewState = viewController.viewState else { return }
        async({
            switch action {
            case .delete:
                _ = try await(self.repository.delete(project: project))
            case .prioritize:
                _ = try await(self.repository.prioritize(project: project, max: viewState.maxPriorityItems))
            case .deprioritize:
                _ = try await(self.repository.deprioritize(project: project))
            }
        }, onError: { _ in
            // TODO: handle
        })
    }

    func viewController(_ viewController: ProjectsViewController, moveRowAt sourceIndexPath: IndexPath,
                        to destinationIndexPath: IndexPath) {
        async({
            guard
                let viewState = viewController.viewState,
                let sourceSection = ProjectSection(rawValue: sourceIndexPath.section),
                let sourceProject = viewState.project(at: sourceIndexPath),
                let destinationSection = ProjectSection(rawValue: destinationIndexPath.section),
                let destinationProject = viewState.project(at: destinationIndexPath) else {
                    return
            }
            if sourceSection == .prioritized, destinationSection == .other {
                _ = try await(self.repository.deprioritize(project: sourceProject))
            } else if sourceSection == .prioritized && destinationSection == .prioritized {
                if sourceIndexPath.row < destinationIndexPath.row {
                    _ = try await(self.repository.prioritise(sourceProject, below: destinationProject))
                } else if sourceIndexPath.row > destinationIndexPath.row {
                    _ = try await(self.repository.prioritise(sourceProject, above: destinationProject))
                }
            } else if sourceSection == .other && destinationSection == .prioritized {
                _ = try await(self.repository.prioritize(project: sourceProject, max: viewState.maxPriorityItems))
            }
            let sections = try await(self.repository.load())
            self.viewController?.viewState = self.viewController?.viewState?.copy(sections: sections)
        }, onError: { _ in
            // TODO: handle
        })
    }
}
