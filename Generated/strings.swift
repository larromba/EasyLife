// swiftlint:disable all
// Generated using SwiftGen, by O.Halligon — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name
internal enum L10n {
  /// %i done
  internal static func iDone(_ p1: Int) -> String {
    return L10n.tr("Localizable", "%i done", p1)
  }
  /// 1 month
  internal static let _1Month = L10n.tr("Localizable", "1 month")
  /// 2 weeks
  internal static let _2Weeks = L10n.tr("Localizable", "2 weeks")
  /// 3 weeks
  internal static let _3Weeks = L10n.tr("Localizable", "3 weeks")
  /// [no name]
  internal static let noName = L10n.tr("Localizable", "[no name]")
  /// a few days
  internal static let aFewDays = L10n.tr("Localizable", "a few days")
  /// a few months
  internal static let aFewMonths = L10n.tr("Localizable", "a few months")
  /// Are you sure?
  internal static let areYouSure = L10n.tr("Localizable", "Are you sure?")
  /// bi-weekly
  internal static let biWeekly = L10n.tr("Localizable", "bi-weekly")
  /// Cancel
  internal static let cancel = L10n.tr("Localizable", "Cancel")
  /// daily
  internal static let daily = L10n.tr("Localizable", "daily")
  /// Delete
  internal static let delete = L10n.tr("Localizable", "Delete")
  /// Deprioritized
  internal static let deprioritized = L10n.tr("Localizable", "Deprioritized")
  /// Done
  internal static let done = L10n.tr("Localizable", "Done")
  /// Edit Project
  internal static let editProject = L10n.tr("Localizable", "Edit Project")
  /// Empty
  internal static let empty = L10n.tr("Localizable", "Empty")
  /// every 6 months
  internal static let every6Months = L10n.tr("Localizable", "every 6 months")
  /// Focus
  internal static let focus = L10n.tr("Localizable", "Focus")
  /// half a year
  internal static let halfAYear = L10n.tr("Localizable", "half a year")
  /// Later
  internal static let later = L10n.tr("Localizable", "Later")
  /// Later...
  internal static let later = L10n.tr("Localizable", "Later...")
  /// Missed...
  internal static let missed = L10n.tr("Localizable", "Missed...")
  /// monthly
  internal static let monthly = L10n.tr("Localizable", "monthly")
  /// name
  internal static let name = L10n.tr("Localizable", "name")
  /// New Project
  internal static let newProject = L10n.tr("Localizable", "New Project")
  /// next week
  internal static let nextWeek = L10n.tr("Localizable", "next week")
  /// next year
  internal static let nextYear = L10n.tr("Localizable", "next year")
  /// No
  internal static let no = L10n.tr("Localizable", "No")
  /// no date
  internal static let noDate = L10n.tr("Localizable", "no date")
  /// OK
  internal static let ok = L10n.tr("Localizable", "OK")
  /// Other
  internal static let other = L10n.tr("Localizable", "Other")
  /// Prioritized
  internal static let prioritized = L10n.tr("Localizable", "Prioritized")
  /// quarterly
  internal static let quarterly = L10n.tr("Localizable", "quarterly")
  /// Split
  internal static let split = L10n.tr("Localizable", "Split")
  /// today
  internal static let today = L10n.tr("Localizable", "today")
  /// Today
  internal static let today = L10n.tr("Localizable", "Today")
  /// tomorow
  internal static let tomorow = L10n.tr("Localizable", "tomorow")
  /// tri-weekly
  internal static let triWeekly = L10n.tr("Localizable", "tri-weekly")
  /// Undo
  internal static let undo = L10n.tr("Localizable", "Undo")
  /// weekly
  internal static let weekly = L10n.tr("Localizable", "weekly")
  /// yearly
  internal static let yearly = L10n.tr("Localizable", "yearly")
  /// Yes
  internal static let yes = L10n.tr("Localizable", "Yes")

  internal enum ErrorLoadingData {
    internal enum PleaseRestartTheAppAndTryAgain {
      /// Error loading data. Please restart the app and try again.\n\nDetailed error:\n%@
      internal static func detailedError(_ p1: String) -> String {
        return L10n.tr("Localizable", "Error loading data. Please restart the app and try again.\n\nDetailed error:\n%@", p1)
      }
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, tableName: table, bundle: Bundle(for: BundleToken.self), comment: "")
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {}
