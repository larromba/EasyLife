import Foundation

protocol HolidayRepositoring: AnyObject {
    var isEnabled: Bool { get set }
}

final class HolidayRepository: HolidayRepositoring {
    var isEnabled: Bool {
        get { return userDefaults.bool(forKey: .holiday) }
        set { userDefaults.set(newValue, forKey: .holiday) }
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
}
