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
    private let dataContextProvider: DataContextProviding
    private let priorityPredicate = NSPredicate(format: "%K != %d",
                                                argumentArray: ["priority", Project.defaultPriority])
    private let otherPredicate = NSPredicate(format: "%K = %d", argumentArray: ["priority", Project.defaultPriority])

    init(dataContextProvider: DataContextProviding) {
        self.dataContextProvider = dataContextProvider
    }

    func delete(project: Project) -> Async<Void> {
        return Async { completion in
            async({
                let context = self.dataContextProvider.mainContext()
                context.delete(project)
                _ = try await(context.save())
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func addProject(name: String) -> Async<Project> {
        return Async { completion in
            async({
                let context = self.dataContextProvider.mainContext()
                let project = context.insert(entityClass: Project.self)
                context.performAndWait {
                    project.name = name
                }
                _ = try await(context.save())
                completion(.success(project))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func updateName(_ name: String, for project: Project) -> Async<Void> {
        return Async { completion in
            async({
                let context = self.dataContextProvider.mainContext()
                context.performAndWait {
                    project.name = name
                }
                _ = try await(context.save())
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
                let context = self.dataContextProvider.mainContext()
                let projects = try await(context.fetch(
                    entityClass: Project.self,
                    sortBy: nil,
                    predicate: self.priorityPredicate)
                )
                context.performAndWait {
                    var available = Set(Array(0..<max))
                    available.subtract(projects.map { Int($0.priority) })
                    let availableSorted = available.sorted(by: <)
                    let nextAvailablePriority = availableSorted.first!
                    project.priority = Int16(nextAvailablePriority)
                }
                _ = try await(context.save())
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func deprioritize(project: Project) -> Async<Void> {
        return Async { completion in
            async({
                let context = self.dataContextProvider.mainContext()
                var predicate: NSPredicate!
                context.performAndWait {
                    predicate = NSPredicate(format: "%K > %d", argumentArray: ["priority", project.priority])
                }
                let projects = try await(context.fetch(
                    entityClass: Project.self,
                    sortBy: nil,
                    predicate: predicate)
                )
                context.performAndWait {
                    projects.forEach { $0.priority -= 1 }
                    project.priority = Int16(Project.defaultPriority)
                }
                _ = try await(context.save())
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func prioritise(_ projectA: Project, above projectB: Project) -> Async<Void> {
        return Async { completion in
            async({
                let context = self.dataContextProvider.mainContext()
                var predicate: NSPredicate!
                var projectADestinationPriority: Int16!
                context.performAndWait {
                    predicate = NSPredicate(
                        format: "%K >= %d AND %K < %d",
                        argumentArray: ["priority", projectB.priority, "priority", projectA.priority]
                    )
                    projectADestinationPriority = projectB.priority
                }
                let projects = try await(context.fetch(
                    entityClass: Project.self,
                    sortBy: nil,
                    predicate: predicate)
                )
                context.performAndWait {
                    projects.forEach { $0.priority += 1 }
                    projectA.priority = projectADestinationPriority
                }
                _ = try await(context.save())
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func prioritise(_ projectA: Project, below projectB: Project) -> Async<Void> {
        return Async { completion in
            async({
                let context = self.dataContextProvider.mainContext()
                var predicate: NSPredicate!
                var projectADestinationPriority: Int16!
                context.performAndWait {
                    projectADestinationPriority = projectB.priority
                    predicate = NSPredicate(
                        format: "%K <= %d AND %K != %d",
                        argumentArray: ["priority", projectB.priority, "priority", Project.defaultPriority]
                    )
                }
                let projects = try await(context.fetch(
                    entityClass: Project.self,
                    sortBy: nil,
                    predicate: predicate)
                )
                context.performAndWait {
                    projects.forEach { $0.priority -= 1 }
                    projectA.priority = projectADestinationPriority
                }
                _ = try await(context.save())
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func fetchPrioritizedProjects() -> Async<[Project]> {
        return Async { completion in
            async({
                let context = self.dataContextProvider.mainContext()
                let projects = try await(context.fetch(
                    entityClass: Project.self,
                    sortBy: DataSort(sortDescriptor: [NSSortDescriptor(key: "priority", ascending: true)]),
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
                let context = self.dataContextProvider.mainContext()
                let projects = try await(context.fetch(
                    entityClass: Project.self,
                    sortBy: DataSort(sortDescriptor: [NSSortDescriptor(key: "name", ascending: true)]),
                    predicate: self.otherPredicate)
                )
                completion(.success(projects))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }
}
