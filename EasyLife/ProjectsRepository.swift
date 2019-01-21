import AsyncAwait
import Foundation

// sourcery: name = ProjectsRepository
protocol ProjectsRepositoring: Mockable {
    func delete(project: Project) -> Async<Void>
    func addProject(name: String) -> Async<Project>
    func updateName(_ name: String, for project: Project) -> Async<Void>
    func prioritize(project: Project, max: Int) -> Async<Void>
    func prioritise(_ projectA: Project, above projectB: Project) -> Async<Void>
    func prioritise(_ projectA: Project, below projectB: Project) -> Async<Void>
    func deprioritize(project: Project) -> Async<Void>
    func fetchPrioritizedProjects() -> Async<[Project]>
    func fetchOtherProjects() -> Async<[Project]>
}

final class ProjectsRepository: ProjectsRepositoring {
    private let dataManager: CoreDataManaging
    private let priorityPredicate = NSPredicate(format: "%K != %d",
                                                argumentArray: ["priority", Project.defaultPriority])
    private let otherPredicate = NSPredicate(format: "%K = %d", argumentArray: ["priority", Project.defaultPriority])

    init(dataManager: CoreDataManaging) {
        self.dataManager = dataManager
    }

    func delete(project: Project) -> Async<Void> {
        return Async { completion in
            async({
                self.dataManager.delete(project, context: .main)
                _ = try await(self.dataManager.save(context: .main))
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func addProject(name: String) -> Async<Project> {
        return Async { completion in
            async({
                let project = self.dataManager.insert(entityClass: Project.self, context: .main)
                project.name = name
                _ = try await(self.dataManager.save(context: .main))
                completion(.success(project))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func updateName(_ name: String, for project: Project) -> Async<Void> {
        return Async { completion in
            async({
                project.name = name
                _ = try await(self.dataManager.save(context: .main))
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func prioritize(project: Project, max: Int) -> Async<Void> {
        assert(max > 0)
        return Async { completion in
            async({
                let projects = try await(self.dataManager.fetch(entityClass: Project.self, sortBy: nil, context: .main,
                                                                predicate: self.priorityPredicate))
                var available = Set(Array(0..<max))
                available.subtract(projects.map { Int($0.priority) })
                let availableSorted = available.sorted(by: <)
                let nextAvailablePriority = availableSorted.first!
                project.priority = Int16(nextAvailablePriority)
                _ = try await(self.dataManager.save(context: .main))
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func deprioritize(project: Project) -> Async<Void> {
        return Async { completion in
            async({
                let predicate = NSPredicate(format: "%K > %d",
                                            argumentArray: ["priority", project.priority])
                let projects = try await(self.dataManager.fetch(entityClass: Project.self, sortBy: nil, context: .main,
                                                                predicate: predicate))
                projects.forEach { $0.priority -= 1 }
                project.priority = Int16(Project.defaultPriority)
                _ = try await(self.dataManager.save(context: .main))
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func prioritise(_ projectA: Project, above projectB: Project) -> Async<Void> {
        return Async { completion in
            async({
                let projectADestinationPriority = projectB.priority
                let predicate = NSPredicate(
                    format: "%K >= %d AND %K < %d",
                    argumentArray: ["priority", projectB.priority, "priority", projectA.priority]
                )
                let projects = try await(self.dataManager.fetch(entityClass: Project.self, sortBy: nil, context: .main,
                                                                predicate: predicate))
                projects.forEach { $0.priority += 1 }
                projectA.priority = projectADestinationPriority
                _ = try await(self.dataManager.save(context: .main))
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func prioritise(_ projectA: Project, below projectB: Project) -> Async<Void> {
        return Async { completion in
            async({
                let projectADestinationPriority = projectB.priority
                let predicate = NSPredicate(
                    format: "%K <= %d AND %K != %d",
                    argumentArray: ["priority", projectB.priority, "priority", Project.defaultPriority]
                )
                let projects = try await(self.dataManager.fetch(entityClass: Project.self, sortBy: nil, context: .main,
                                                                predicate: predicate))
                projects.forEach { $0.priority -= 1 }
                projectA.priority = projectADestinationPriority
                _ = try await(self.dataManager.save(context: .main))
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func fetchPrioritizedProjects() -> Async<[Project]> {
        return Async { completion in
            async({
                let projects = try await(self.dataManager.fetch(
                    entityClass: Project.self,
                    sortBy: [NSSortDescriptor(key: "priority", ascending: true)],
                    context: .main,
                    predicate: self.priorityPredicate)
                )
                completion(.success(projects))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func fetchOtherProjects() -> Async<[Project]> {
        return Async { completion in
            async({
                let projects = try await(self.dataManager.fetch(
                    entityClass: Project.self,
                    sortBy: [NSSortDescriptor(key: "name", ascending: true)],
                    context: .main,
                    predicate: self.otherPredicate)
                )
                completion(.success(projects))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }
}
