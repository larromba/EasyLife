// swiftlint:disable all
// Generated using SwiftGen, by O.Halligon — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name
internal enum L10n {
  /// Time's up!
  internal static let alarmNotificationBody = L10n.tr("Localizable", "alarm notification body")
  /// Alarm
  internal static let alarmNotificationTitle = L10n.tr("Localizable", "alarm notification title")
  /// Are you sure?
  internal static let archiveDeleteAllMessage = L10n.tr("Localizable", "archive delete all message")
  /// No
  internal static let archiveDeleteAllOptionNo = L10n.tr("Localizable", "archive delete all option no")
  /// Yes
  internal static let archiveDeleteAllOptionYes = L10n.tr("Localizable", "archive delete all option yes")
  /// Empty
  internal static let archiveDeleteAllTitle = L10n.tr("Localizable", "archive delete all title")
  /// %i done
  internal static func archiveItemTotalMessage(_ p1: Int) -> String {
    return L10n.tr("Localizable", "archive item total message", p1)
  }
  /// Undo
  internal static let archiveItemUndoOption = L10n.tr("Localizable", "archive item undo option")
  /// Something went wrong with the database. Please try again. If the problem persists, please delete and reinstall the app
  internal static let dataErrorMessage = L10n.tr("Localizable", "data error message")
  /// Error
  internal static let dataErrorTitle = L10n.tr("Localizable", "data error title")
  /// 1 month
  internal static let dateOption1Month = L10n.tr("Localizable", "date option 1 month")
  /// 2 weeks
  internal static let dateOption2Weeks = L10n.tr("Localizable", "date option 2 weeks")
  /// 3 weeks
  internal static let dateOption3Weeks = L10n.tr("Localizable", "date option 3 weeks")
  /// a few days
  internal static let dateOptionAFewDays = L10n.tr("Localizable", "date option a few days")
  /// a few months
  internal static let dateOptionAFewMonths = L10n.tr("Localizable", "date option a few months")
  /// half a year
  internal static let dateOptionHalfAYear = L10n.tr("Localizable", "date option half a year")
  /// next week
  internal static let dateOptionNextWeek = L10n.tr("Localizable", "date option next week")
  /// next year
  internal static let dateOptionNextYear = L10n.tr("Localizable", "date option next year")
  /// today
  internal static let dateOptionToday = L10n.tr("Localizable", "date option today")
  /// tomorow
  internal static let dateOptionTomorow = L10n.tr("Localizable", "date option tomorow")
  /// Cancel
  internal static let editProjectAlertCancel = L10n.tr("Localizable", "edit project alert cancel")
  /// OK
  internal static let editProjectAlertOk = L10n.tr("Localizable", "edit project alert ok")
  /// name
  internal static let editProjectAlertPlaceholder = L10n.tr("Localizable", "edit project alert placeholder")
  /// Edit Project
  internal static let editProjectAlertTitle = L10n.tr("Localizable", "edit project alert title")
  /// Empty
  internal static let emptyTableText = L10n.tr("Localizable", "empty table text")
  /// Error loading data. Please restart the app and try again.\n\nDetailed error:\n%@
  internal static func errorLoadingDataMessage(_ p1: String) -> String {
    return L10n.tr("Localizable", "error loading data message", p1)
  }
  /// Focus
  internal static let focusModeStart = L10n.tr("Localizable", "focus mode start")
  /// Stop
  internal static let focusModeStop = L10n.tr("Localizable", "focus mode stop")
  /// 10 Minutes
  internal static let focusTime10m = L10n.tr("Localizable", "focus time 10m")
  /// 15 Minutes
  internal static let focusTime15m = L10n.tr("Localizable", "focus time 15m")
  /// 1 Hour
  internal static let focusTime1h = L10n.tr("Localizable", "focus time 1h")
  /// 20 Minutes
  internal static let focusTime20m = L10n.tr("Localizable", "focus time 20m")
  /// 30 Minutes
  internal static let focusTime30m = L10n.tr("Localizable", "focus time 30m")
  /// 45 Minutes
  internal static let focusTime45m = L10n.tr("Localizable", "focus time 45m")
  /// 5 Minutes
  internal static let focusTime5m = L10n.tr("Localizable", "focus time 5m")
  /// Later...
  internal static let laterSection = L10n.tr("Localizable", "later section")
  /// Missed...
  internal static let missedSection = L10n.tr("Localizable", "missed section")
  /// New Project
  internal static let newProjectAlertTitle = L10n.tr("Localizable", "new project alert title")
  /// no date
  internal static let noDate = L10n.tr("Localizable", "no date")
  /// Deprioritize
  internal static let projectOptionDeprioritize = L10n.tr("Localizable", "project option deprioritize")
  /// Prioritize
  internal static let projectOptionPrioritize = L10n.tr("Localizable", "project option prioritize")
  /// Deprioritized
  internal static let projectSectionDeprioritized = L10n.tr("Localizable", "project section deprioritized")
  /// Prioritized
  internal static let projectSectionPrioritized = L10n.tr("Localizable", "project section prioritized")
  /// Your items are all blocking one another, which means nothing can be completed! Please unblock something and try again
  internal static let recursivelyBlockedAlertMessage = L10n.tr("Localizable", "recursively blocked alert message")
  /// Ok
  internal static let recursivelyBlockedAlertOk = L10n.tr("Localizable", "recursively blocked alert ok")
  /// All Blocked
  internal static let recursivelyBlockedAlertTitle = L10n.tr("Localizable", "recursively blocked alert title")
  /// bi-monthly
  internal static let repeatOptionBiMonthly = L10n.tr("Localizable", "repeat option biMonthly")
  /// bi-weekly
  internal static let repeatOptionBiWeekly = L10n.tr("Localizable", "repeat option biWeekly")
  /// daily
  internal static let repeatOptionDaily = L10n.tr("Localizable", "repeat option daily")
  /// every 6 months
  internal static let repeatOptionEvery6Months = L10n.tr("Localizable", "repeat option every 6 months")
  /// monthly
  internal static let repeatOptionMonthly = L10n.tr("Localizable", "repeat option monthly")
  /// quarterly
  internal static let repeatOptionQuarterly = L10n.tr("Localizable", "repeat option quarterly")
  /// tri-weekly
  internal static let repeatOptionTriWeekly = L10n.tr("Localizable", "repeat option triWeekly")
  /// weekly
  internal static let repeatOptionWeekly = L10n.tr("Localizable", "repeat option weekly")
  /// yearly
  internal static let repeatOptionYearly = L10n.tr("Localizable", "repeat option yearly")
  /// Today
  internal static let todaySection = L10n.tr("Localizable", "today section")
  /// [no name]
  internal static let todoItemNoName = L10n.tr("Localizable", "todo item no name")
  /// Delete
  internal static let todoItemOptionDelete = L10n.tr("Localizable", "todo item option delete")
  /// Done
  internal static let todoItemOptionDone = L10n.tr("Localizable", "todo item option done")
  /// Later
  internal static let todoItemOptionLater = L10n.tr("Localizable", "todo item option later")
  /// Split
  internal static let todoItemOptionSplit = L10n.tr("Localizable", "todo item option split")
  /// There are items in the today section blocked by items in other sections. To use focus mode, you'll need to consolidate these items into the today section. Would you like to do this now?
  internal static let unfocusableAlertMessage = L10n.tr("Localizable", "unfocusable alert message")
  /// No
  internal static let unfocusableAlertNo = L10n.tr("Localizable", "unfocusable alert no")
  /// Missing Items
  internal static let unfocusableAlertTitle = L10n.tr("Localizable", "unfocusable alert title")
  /// Yes
  internal static let unfocusableAlertYes = L10n.tr("Localizable", "unfocusable alert yes")
  /// Do you want to save your changes?
  internal static let unsavedChangesMessage = L10n.tr("Localizable", "unsaved changes message")
  /// No
  internal static let unsavedChangesNo = L10n.tr("Localizable", "unsaved changes no")
  /// Unsaved Changed
  internal static let unsavedChangesTitle = L10n.tr("Localizable", "unsaved changes title")
  /// Yes
  internal static let unsavedChangesYes = L10n.tr("Localizable", "unsaved changes yes")
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
