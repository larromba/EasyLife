import Foundation
import CoreData

extension TodoItem {
    var repeatState: RepeatState? {
        get {
            return RepeatState(rawValue: Int(repeats))
        }
        set {
            repeats = Int16(newValue?.rawValue ?? 0)
        }
    }

    func incrementDate() {
        guard
            let oldDate = date,
            let repeatState = repeatState,
            let incrementedDate = repeatState.increment(date: oldDate) else {
                return
        }
        self.date = incrementedDate
        if incrementedDate < Date() {
            incrementDate()
        }
    }
}
