import Foundation

protocol Segueable {
    func performSegue(withIdentifier identifier: String, sender: Any?)
}
