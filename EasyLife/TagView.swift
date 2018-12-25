import UIKit

protocol TagViewable {
    var viewState: TagViewStating? { get set }
}

@IBDesignable
class TagView: UIView, TagViewable {
    @IBOutlet private(set) weak var label: UILabel!
    @IBOutlet private(set) weak var cornerLayerView: UIView!
    @IBInspectable private var cornerColor: UIColor? {
        didSet { cornerLayer?.fillColor = cornerColor?.cgColor }
    }
    private var cornerLayer: CAShapeLayer?

    var viewState: TagViewStating? {
        didSet { _ = viewState.map(bind) }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadXib()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadXib()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        let path = UIBezierPath()
        var point = CGPoint(x: 0, y: 0)
        path.move(to: point)

        point.x = rect.width
        path.addLine(to: point)

        point.x = 0.0
        point.y = rect.height
        path.addLine(to: point)
        path.close()

        let layer = CAShapeLayer()
        layer.frame = rect
        layer.path = path.cgPath
        layer.fillColor = cornerColor?.cgColor
        cornerLayerView.layer.addSublayer(layer)
        self.cornerLayer = layer
    }

    // MARK: - private

    private func bind(_ viewState: TagViewStating) {
        label.text = viewState.labelText
        cornerLayerView.isHidden = viewState.isHidden
        cornerColor = viewState.cornerColor
    }
}
