import Foundation

enum CoreDataError: Error {
    case missingEntitiyName
    case notLoaded
    case copy
    case entityDescription
    case frameworkError(Error)
}
