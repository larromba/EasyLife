import Foundation

enum CoreDataError: LocalizedError {
    case missingEntitiyName
    case notLoaded
    case copy
    case entityDescription
    case frameworkError(Error)

    var errorDescription: String? {
        return L10n.dataErrorMessage
    }
}

enum BadgeError: Error {
    case unauthorized
    case frameworkError(Error)
}
