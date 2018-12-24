import Foundation

enum CoreDataError: Error {
    case missingEntitiyName
    case entityDescription
    case frameworkError(Error)
}
