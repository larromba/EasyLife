import UIKit

protocol StoryboardRouting: AnyObject {
    func handleSegue(_ segue: UIStoryboardSegue, sender: Any?)
}
