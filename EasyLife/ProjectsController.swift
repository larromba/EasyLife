import AsyncAwait
import Foundation
import UIKit

// sourcery: name = ProjectsController
protocol ProjectsControlling: AnyObject, Mockable {
    func setViewController(_ viewController: ProjectsViewControlling)
    func setAlertController(_ alertController: AlertControlling)
    func setDelegate(_ delegate: ProjectsControllerDelegate)
}

protocol ProjectsControllerDelegate: AnyObject {
    func controllerFinished(_ controller: ProjectsController)
}

final class ProjectsController: ProjectsControlling {
    private let repository: ProjectsRepositoring
    private weak var viewController: ProjectsViewControlling?
    private var alertController: AlertControlling?
    private weak var delegate: ProjectsControllerDelegate?
    private var editContext: ValueContext<String?>?

    init(repository: ProjectsRepositoring) {
        self.repository = repository
    }

    func setViewController(_ viewController: ProjectsViewControlling) {
        self.viewController = viewController
        viewController.setDelegate(self)
        viewController.viewState = ProjectsViewState(sections: [:], isEditing: false)
        reload()
    }

    func setAlertController(_ alertController: AlertControlling) {
        self.alertController = alertController
    }

    func setDelegate(_ delegate: ProjectsControllerDelegate) {
        self.delegate = delegate
    }

    // MARK: - private

    private func reload() {
        guard let viewState = viewController?.viewState else { return }
        async({
            let prioritizedProjects = try await(self.repository.fetchPrioritizedProjects())
            let otherProjects = try await(self.repository.fetchOtherProjects())
            let sections = [
                ProjectSection.prioritized: prioritizedProjects,
                ProjectSection.other: otherProjects
            ]
            onMain {
                self.viewController?.viewState = viewState.copy(sections: sections)
            }
        }, onError: { error in
            onMain { self.alertController?.showAlert(Alert(error: error)) }
        })
    }

    private func addProject(name: String) {
        async({
            _ = try await(self.repository.addProject(name: name))
            self.reload()
        }, onError: { error in
            onMain { self.alertController?.showAlert(Alert(error: error)) }
        })
    }

    private func updateName(_ name: String, forProject project: Project) {
        async({
            _ = try await(self.repository.updateName(name, for: project))
            self.reload()
        }, onError: { error in
            onMain { self.alertController?.showAlert(Alert(error: error)) }
        })
    }

    private func editProject(_ project: Project?) {
        let action = Alert.Action(title: L10n.editProjectAlertOk, handler: {
            guard let name = self.editContext?.value else { return }
            if let project = project {
                self.updateName(name, forProject: project)
            } else {
                self.addProject(name: name)
            }
            self.editContext = nil
        })
        let textField = Alert.TextField(placeholder: L10n.editProjectAlertPlaceholder, text: project?.name,
                                        handler: { text in
            self.editContext?.value = text
            if let isEmpty = text?.isEmpty {
                self.alertController?.setIsButtonEnabled(!isEmpty, at: 1)
            }
        })
        let isNewProject = (project == nil)
        let alert = Alert(title: isNewProject ? L10n.newProjectAlertTitle : L10n.editProjectAlertTitle,
                          message: "",
                          cancel: Alert.Action(title: L10n.editProjectAlertCancel, handler: nil),
                          actions: [action],
                          textField: textField)
        editContext = ValueContext(value: project?.name)
        alertController?.showAlert(alert)
        alertController?.setIsButtonEnabled(false, at: 1)
    }

    private func toggleEditTable() {
        guard let viewState = viewController?.viewState else { return }
        viewController?.viewState = viewState.copy(isEditing: !viewState.isEditing)
    }
}

// MARK: - ProjectsViewControllerDelegate

extension ProjectsController: ProjectsViewControllerDelegate {
    func viewController(_ viewController: ProjectsViewController, performAction action: ProjectsAction) {
        switch action {
        case .add: editProject(nil)
        case .edit(let project): editProject(project)
        case .editTable: toggleEditTable()
        case .done: delegate?.controllerFinished(self)
        }
    }

    func viewController(_ viewController: ProjectsViewController, performAction action: ProjectItemAction,
                        forProject project: Project) {
        guard let viewState = viewController.viewState else { return }
        async({
            switch action {
            case .delete: _ = try await(self.repository.delete(project: project))
            case .prioritize: _ = try await(self.repository.prioritize(project: project,
                                                                       max: viewState.maxPriorityItems))
            case .deprioritize: _ = try await(self.repository.deprioritize(project: project))
            }
            self.reload()
        }, onError: { error in
            onMain { self.alertController?.showAlert(Alert(error: error)) }
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
            self.reload()
        }, onError: { error in
            onMain { self.alertController?.showAlert(Alert(error: error)) }
        })
    }
}
