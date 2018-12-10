import UIKit

class FatalViewController: UIViewController {
    @IBOutlet weak var label: UILabel!

    var error: Error?

    override func viewDidLoad() {
        if let error = error {
            label.text = String(format: "Error loading data. Please restart the app and try again.\n\nDetailed error:\n%@".localized, error.localizedDescription)
        }
    }
}
