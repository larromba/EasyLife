import Foundation

enum CoreDataError: Error {
    case missingEntitiyName
    case copy
    case entityDescription
    case frameworkError(Error)
}
