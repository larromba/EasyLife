import UIKit

@IBDesignable class TagView: UIView {
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
                cornerColor = .priority1
            case 1:
                cornerColor = .priority2
            case 2:
                cornerColor = .priority3
            case 3:
                cornerColor = .priority4
            case 4:
                cornerColor = .priority5
            default:
                break
            }
        } else {
            isHidden = true
        }
    }
}
