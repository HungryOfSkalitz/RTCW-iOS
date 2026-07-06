import UIKit
import CoreGraphics

protocol JoystickDelegate: AnyObject {
    func handleJoyStick(angle: CGFloat, displacement: CGFloat)
    func handleJoyStickPosition(x: CGFloat, y: CGFloat)
}

public typealias JoyStickViewMonitor = (_ angle: CGFloat, _ displacement: CGFloat) -> ()

public final class JoyStickView: UIView {
    
    weak var delegate: JoystickDelegate?
    
    public var monitor: JoyStickViewMonitor? = nil
    
    public var movable: Bool = true
    public var movableBounds: CGRect?
    
    public var baseAlpha: CGFloat {
        get { return baseImageView.alpha }
        set { baseImageView.alpha = newValue }
    }
    
    public var handleTintColor: UIColor! {
        didSet { makeHandleImage() }
    }
    
    public private(set) var angle: CGFloat = 0.0
    public private(set) var displacement: CGFloat = 0.0
    
    private lazy var radius: CGFloat = { return self.bounds.size.width / 2.0 }()
    
    private let baseImage = UIImage(named: "JoyStickBase")!
    private let handleImage = UIImage(named: "JoyStickHandle")!
    
    private var baseImageView: UIImageView!
    private var handleImageView: UIImageView!
    
    private var lastAngleRadians: Float = 0.0
    private var originalCenter: CGPoint?
    private var tapGestureRecognizer: UITapGestureRecognizer!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    private func initialize() {
        handleTintColor = tintColor
        
        baseImageView = UIImageView(image: baseImage)
        baseImageView.alpha = 0.5
        addSubview(baseImageView)
        baseImageView.frame = bounds
        
        handleImageView = UIImageView(image: handleImage)
        makeHandleImage()
        addSubview(handleImageView)
        handleImageView.frame = bounds.insetBy(dx: 0.15 * bounds.width, dy: 0.15 * bounds.height)
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(resetFrame))
        tapGestureRecognizer!.numberOfTapsRequired = 2
        addGestureRecognizer(tapGestureRecognizer!)
    }
    
    private func makeHandleImage() {
        guard handleImageView != nil else { return }
        guard let inputImage = CIImage(image: handleImage) else {
            fatalError("failed to create input CIImage")
        }
        
        let filterConfig: [String:Any] = [kCIInputIntensityKey: 1.0,
                                          kCIInputColorKey: CIColor(color: handleTintColor!),
                                          kCIInputImageKey: inputImage]
        guard let filter = CIFilter(name: "CIColorMonochrome", parameters: filterConfig) else {
            fatalError("failed to create CIFilter CIColorMonochrome")
        }
        
        guard let outputImage = filter.outputImage else {
            fatalError("failed to obtain output CIImage")
        }
        
        handleImageView.image = UIImage(ciImage: outputImage)
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        updatePosition(touch: touch)
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        updatePosition(touch: touch)
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetPosition()
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetPosition()
    }
    
    @objc public func resetFrame() {
        if displacement < 0.5 && originalCenter != nil {
            center = originalCenter!
            originalCenter = nil
        }
    }
    
    private func resetPosition() {
        updateLocation(location: CGPoint(x: frame.midX, y: frame.midY))
        self.delegate?.handleJoyStick(angle: 0, displacement: 0)
    }
    
    private func updatePosition(touch: UITouch) {
        updateLocation(location: touch.location(in: superview!))
    }
    
    private func updateLocation(location: CGPoint) {
        guard let superview = self.superview else { return }
        guard superview.bounds.contains(location) else { return }
        
        let deltaX = location.x - frame.midX
        let deltaY = location.y - frame.midY
        let magnitude = sqrt(deltaX * deltaX + deltaY * deltaY)
        let newDisplacement = magnitude / radius
        let newAngleRadians = atan2f(Float(deltaX), Float(deltaY))
        
        if movable {
            if newDisplacement > 1.0 {
                if originalCenter == nil {
                    originalCenter = center
                }
                let endX = CGFloat(sinf(newAngleRadians)) * radius
                let eadyY = CGFloat(cosf(newAngleRadians)) * radius
                let origin = CGPoint(x: location.x - endX - frame.width / 2.0, y: location.y - eadyY - frame.height / 2.0)
                
                if let bounds = movableBounds {
                    frame.origin = CGPoint(x: min(max(origin.x, bounds.minX), bounds.maxX - frame.width),
                                           y: min(max(origin.y, bounds.minY), bounds.maxY - frame.height))
                } else {
                    frame.origin = origin
                }
            }
            handleImageView.center = CGPoint(x: bounds.midX + deltaX, y: bounds.midY + deltaY)
        } else {
            if newDisplacement > 1.0 {
                let x = CGFloat(sinf(newAngleRadians)) * radius
                let y = CGFloat(cosf(newAngleRadians)) * radius
                handleImageView.frame.origin = CGPoint(x: x + bounds.midX - handleImageView.bounds.size.width / 2.0,
                                                       y: y + bounds.midY - handleImageView.bounds.size.height / 2.0)
            } else {
                handleImageView.center = CGPoint(x: bounds.midX + deltaX, y: bounds.midY + deltaY)
            }
        }
        
        let newClampedDisplacement = min(newDisplacement, 1.0)
        if newClampedDisplacement != displacement || newAngleRadians != lastAngleRadians {
            displacement = newClampedDisplacement
            lastAngleRadians = newAngleRadians
            
            self.angle = newClampedDisplacement != 0.0 ? CGFloat(180.0 - newAngleRadians * 180.0 / Float.pi) : 0.0
            self.delegate?.handleJoyStick(angle: angle, displacement: displacement)
            
            let new_x = deltaX / radius
            let new_y = -(deltaY / radius)
            self.delegate?.handleJoyStickPosition(x: new_x, y: new_y)
        }
    }
}

public func LiangBarsky(rect: CGRect, p0: CGPoint, p1: CGPoint) -> (p0: CGPoint, p1: CGPoint, inRect: Bool) {
    let edgeLeft = rect.minX
    let edgeRight = rect.maxX
    let edgeBottom = rect.minY
    let edgeTop = rect.maxY
    
    var t0: CGFloat = 0.0
    var t1: CGFloat = 1.0
    let xd = p1.x - p0.x
    let yd = p1.y - p0.y
    let cases = [(-xd, -(edgeLeft -   p0.x)),
                 ( xd,   edgeRight -  p0.x),
                 (-yd, -(edgeBottom - p0.y)),
                 ( yd,   edgeTop -    p0.y)]
    
    let epsilon: CGFloat = 1.0e-8
    
    for (p, q) in cases {
        if abs(p) < epsilon {
            if q < 0.0 {
                return (p0: p0, p1: p1, inRect: false)
            }
        }
        else {
            let r: CGFloat = q / p
            if p < 0.0 {
                if r > t1 {
                    return (p0: p0, p1: p1, inRect: false)
                }
                else if r > t0 {
                    t0 = r
                }
            }
            else if p > 0.0 {
                if r < t0 {
                    return (p0: p0, p1: p1, inRect: false)
                }
                else if r < t1 {
                    t1 = r
                }
            }
        }
    }
    
    return (p0: CGPoint(x: p0.x + t0 * xd, y: p0.y + t0 * yd),
            p1: CGPoint(x: p0.x + t1 * xd, y: p0.y + t1 * yd),
            inRect: true)
}


