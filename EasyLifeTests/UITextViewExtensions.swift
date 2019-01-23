import Foundation

extension UITextView {
    func setText(_ text: String) {
        self.text = text
        self.delegate?.textViewDidChange?(self)
    }
}
