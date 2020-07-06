import Foundation

extension UserDefaults {
    func bool(forKey key: UserDefaultsKey) -> Bool {
        return bool(forKey: key.rawValue)
    }

    func set(_ value: Bool, forKey key: UserDefaultsKey) {
        set(value, forKey: key.rawValue)
    }
}
