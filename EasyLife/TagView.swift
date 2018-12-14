import UIKit

@IBDesignable
class TagView: UIView {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var cornerLayerView: UIView!
    private var cornerLayer: CAShapeLayer?
    @IBInspectable var cornerColor: UIColor = .clear {
        didSet {
            cornerLayer?.fillColor = cornerColor.cgColor
        }
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
        layer.fillColor = cornerColor.cgColor
        cornerLayerView.layer.addSublayer(layer)
        self.cornerLayer = layer
    }

    func setup(for project: Project?) {
        if let priority = project?.priority, priority != Project.defaultPriority {
            isHidden = false
            label.text = "\(priority + 1)"
            switch priority {
            case 0:
                cornerColor = Asset.Colors.priority1.color
            case 1:
                cornerColor = Asset.Colors.priority2.color
            case 2:
                cornerColor = Asset.Colors.priority3.color
            case 3:
                cornerColor = Asset.Colors.priority4.color
            case 4:
                cornerColor = Asset.Colors.priority5.color
            default:
                break
            }
        } else {
            isHidden = true
        }
    }
}
