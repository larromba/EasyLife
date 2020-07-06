import Foundation

enum CoreDataError: LocalizedError {
    case missingEntitiyName
    case notLoaded
    case entityDescription
    case frameworkError(Error)

    var errorDescription: String? {
        return L10n.dataErrorMessage
    }
}

enum NotificationAuthorizationError: LocalizedError {
    case unauthorized
    case frameworkError(Error)

    var errorDescription: String? {
        return L10n.notificationErrorMessage
    }
}
