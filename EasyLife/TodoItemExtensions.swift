import CoreData
import Foundation

extension TodoItem {
    var repeatState: RepeatState {
        get {
            return RepeatState(rawValue: Int(repeats)) ?? .default
        }
        set {
            repeats = Int16(newValue.rawValue)
        }
    }

    func incrementDate() {
        guard
            let oldDate = date,
            let incrementedDate = repeatState.increment(date: oldDate) else {
                return
        }
        self.date = incrementedDate
        if incrementedDate < Date() {
            incrementDate()
        }
    }
}
