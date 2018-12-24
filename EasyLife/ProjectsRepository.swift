import AsyncAwait
import Foundation

protocol ProjectsRepositoring {
    func delete(project: Project) -> Async<Void>
    func addProject(name: String) -> Async<Project>
    func prioritize(project: Project, max: Int) -> Async<Void>
    func prioritise(_ projectA: Project, above projectB: Project) -> Async<Void>
    func prioritise(_ projectA: Project, below projectB: Project) -> Async<Void>
    func deprioritize(project: Project) -> Async<Void>
    func updateName(name: String, for project: Project) -> Async<Void>
    func load() -> Async<[ProjectSection: [Project]]>
}

final class ProjectsRepository: ProjectsRepositoring {
    private let dataManager: CoreDataManager
    private let priorityPredicate = NSPredicate(format: "%K != %d",
                                                argumentArray: ["priority", Project.defaultPriority])
    private let otherPredicate = NSPredicate(format: "%K = %d", argumentArray: ["priority", Project.defaultPriority])

    init(dataManager: CoreDataManager) {
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

    func prioritize(project: Project, max: Int) -> Async<Void> {
        return Async { completion in
            async({
                let projects = try await(self.dataManager.fetch(entityClass: Project.self, context: .main,
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
                projectA.priority = projectB.priority
                projectB.priority += 1
                let predicate = NSPredicate(format: "%K > %d", argumentArray: ["priority", projectB.priority])
                let projects = try await(self.dataManager.fetch(entityClass: Project.self, context: .main,
                                                                predicate: predicate))
                projects.forEach { $0.priority += 1 }
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
                projectA.priority = projectB.priority
                projectB.priority -= 1
                let predicate = NSPredicate(format: "%K < %d", argumentArray: ["priority", projectB.priority])
                let projects = try await(self.dataManager.fetch(entityClass: Project.self, context: .main,
                                                                predicate: predicate))
                projects.forEach { $0.priority -= 1 }
                _ = try await(self.dataManager.save(context: .main))
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func updateName(name: String, for project: Project) -> Async<Void> {
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

    func load() -> Async<[ProjectSection: [Project]]> {
        return Async { completion in
            async({
                let priotitizedProjects = try await(self.dataManager.fetch(
                    entityClass: Project.self,
                    sortBy: [NSSortDescriptor(key: "priority", ascending: true)],
                    context: .main,
                    predicate: self.priorityPredicate)
                )
                let otherProjects = try await(self.dataManager.fetch(
                    entityClass: Project.self,
                    sortBy: [NSSortDescriptor(key: "name", ascending: true)],
                    context: .main,
                    predicate: self.otherPredicate)
                )
                completion(.success([.prioritized: priotitizedProjects, .other: otherProjects]))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }
}
