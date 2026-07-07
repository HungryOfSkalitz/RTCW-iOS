//
//  SDL2ViewController+Additions.swift
//  Quake2-iOS
//
//  Created by Tom Kidd on 1/28/19.
//

import UIKit

extension SDL_uikitviewcontroller {
    
    // A method of getting around the fact that Swift extensions cannot have stored properties
    // https://medium.com/@valv0/computed-properties-and-extensions-a-pure-swift-approach-64733768112c
    struct Holder {
        static var _fireButton = UIButton()
        static var _jumpButton = UIButton()
        static var _useButton = UIButton()
        static var _crouchButton = UIButton()
        static var _joystickView = JoyStickView(frame: .zero)
        static var _tildeButton = UIButton()
        static var _expandButton = UIButton()
        static var _escapeButton = UIButton()
        static var _quickSaveButton: UIButton!
        static var _quickLoadButton: UIButton!
        static var _buttonStack = UIStackView(frame: .zero)
        static var _buttonStackExpanded = false
        static var _f1Button = UIButton()
        static var _prevWeaponButton = UIButton()
        static var _nextWeaponButton = UIButton()
        static var _crouching = false
        static var _factor:CGFloat = UIScreen.main.scale
        
        
        static var _panGesture = UIPanGestureRecognizer()
        static var _lastPanPoint = CGPoint.zero
        static var _isPanning = false
    }
    
    var fireButton:UIButton {
        get { return Holder._fireButton }
        set(newValue) { Holder._fireButton = newValue }
    }
    
    var jumpButton:UIButton {
        get { return Holder._jumpButton }
        set(newValue) { Holder._jumpButton = newValue }
    }
    
    var useButton:UIButton {
        get { return Holder._useButton }
        set(newValue) { Holder._useButton = newValue }
    }
    
    var crouchButton:UIButton {
        get { return Holder._crouchButton }
        set(newValue) { Holder._crouchButton = newValue }
    }
    
    var joystickView:JoyStickView {
        get { return Holder._joystickView }
        set(newValue) { Holder._joystickView = newValue }
    }
    
    var tildeButton:UIButton {
        get { return Holder._tildeButton }
        set(newValue) { Holder._tildeButton = newValue }
    }
    
    var expandButton:UIButton {
        get { return Holder._expandButton }
        set(newValue) { Holder._expandButton = newValue }
    }
    
    var escapeButton:UIButton {
        get { return Holder._escapeButton }
        set(newValue) { Holder._escapeButton = newValue }
    }
    
    var quickSaveButton:UIButton {
        get { return Holder._quickSaveButton }
        set(newValue) { Holder._quickSaveButton = newValue }
    }
    
    var quickLoadButton:UIButton {
        get { return Holder._quickLoadButton }
        set(newValue) { Holder._quickLoadButton = newValue }
    }
    
    var buttonStack:UIStackView {
        get { return Holder._buttonStack }
        set(newValue) { Holder._buttonStack = newValue }
    }
    
    var buttonStackExpanded:Bool {
        get { return Holder._buttonStackExpanded }
        set(newValue) { Holder._buttonStackExpanded = newValue }
    }
    
    var f1Button:UIButton {
        get { return Holder._f1Button }
        set(newValue) { Holder._f1Button = newValue }
    }
    
    var prevWeaponButton:UIButton {
        get { return Holder._prevWeaponButton }
        set(newValue) { Holder._prevWeaponButton = newValue }
    }
    
    var nextWeaponButton:UIButton {
        get { return Holder._nextWeaponButton }
        set(newValue) { Holder._nextWeaponButton = newValue }
    }
    
    var crouching:Bool {
        get { return Holder._crouching }
        set(newValue) { Holder._crouching = newValue }
    }
    
    var factor:CGFloat {
        get { return Holder._factor }
        set(newValue) { Holder._factor = newValue }
    }
    
    
    var panGesture: UIPanGestureRecognizer {
        get { return Holder._panGesture }
        set(newValue) { Holder._panGesture = newValue }
    }
    var lastPanPoint: CGPoint {
        get { return Holder._lastPanPoint }
        set(newValue) { Holder._lastPanPoint = newValue }
    }
    var isPanning: Bool {
        get { return Holder._isPanning }
        set(newValue) { Holder._isPanning = newValue }
    }
    
    @objc func firePressed(_ sender: UIButton) {
        Key_Event(130, qboolean(1), qboolean(1))
    }
    
    @objc func fireReleased(_ sender: UIButton) {
        Key_Event(130, qboolean(0), qboolean(1))
    }
    
    @objc func jumpPressed(_ sender: UIButton) {
        Key_Event(131, qboolean(1), qboolean(1))
    }
    
    @objc func jumpReleased(_ sender: UIButton) {
        Key_Event(131, qboolean(0), qboolean(1))
    }
    
    @objc func usePressed(_ sender: UIButton) {
        Key_Event(101, qboolean(1), qboolean(1))
    }
    
    @objc func useReleased(_ sender: UIButton) {
        Key_Event(101, qboolean(0), qboolean(1))
    }
    
    @objc func crouchPressed(_ sender: UIButton) {
        crouching = !crouching
        Key_Event(136, crouching ? qboolean(1) : qboolean(0), qboolean(1))
    }
    
    @objc func prevWeaponPressed(_ sender: UIButton) {
        Key_Event(91, qboolean(1), qboolean(1))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            Key_Event(91, qboolean(0), qboolean(1))
        }
    }
    
    @objc func nextWeaponPressed(_ sender: UIButton) {
        Key_Event(93, qboolean(1), qboolean(1))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            Key_Event(93, qboolean(0), qboolean(1))
        }
    }
    
    @objc func toggleControls(_ hide: Bool) {
        self.fireButton.isHidden = hide
        self.jumpButton.isHidden = hide
        self.useButton.isHidden = hide
        self.crouchButton.isHidden = hide
        self.joystickView.isHidden = hide
        self.buttonStack.isHidden = hide
        self.prevWeaponButton.isHidden = hide
        self.nextWeaponButton.isHidden = hide
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        if !self.view.gestureRecognizers!.contains(panGesture) {
            panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handleCameraPan(_:)))
            panGesture.maximumNumberOfTouches = 1
            self.view.addGestureRecognizer(panGesture)
        }
    }
    
    @objc func handleCameraPan(_ gesture: UIPanGestureRecognizer) {
        let currentPoint = gesture.location(in: self.view)
        
        switch gesture.state {
        case .began:
           
            if currentPoint.x > (self.view.bounds.width / 2.0) {
                lastPanPoint = currentPoint
                isPanning = true
            } else {
                isPanning = false
            }
            
        case .changed:
            guard isPanning else { return }
            
            let deltaX = currentPoint.x - lastPanPoint.x
            let deltaY = currentPoint.y - lastPanPoint.y
            
            let sens: CGFloat = 1.5
            let maxJoyValue: CGFloat = 40.0
            
            
            let joyX = deltaX * sens
            if joyX > 0.5 {
                cl_joyscale_x.0 = Int32(min(abs(joyX) * 15, maxJoyValue))
                cl_joyscale_x.1 = 0
                Key_Event(135, qboolean(1), qboolean(1)) 
                Key_Event(134, qboolean(0), qboolean(1)) 
            } else if joyX < -0.5 {
                cl_joyscale_x.1 = Int32(min(abs(joyX) * 15, maxJoyValue))
                cl_joyscale_x.0 = 0
                Key_Event(134, qboolean(1), qboolean(1)) 
                Key_Event(135, qboolean(0), qboolean(1)) 
            }
            
            
            let joyY = deltaY * sens
            if joyY > 0.5 {
                cl_joyscale_y.0 = Int32(min(abs(joyY) * 20, maxJoyValue))
                cl_joyscale_y.1 = 0
                Key_Event(133, qboolean(1), qboolean(1)) 
                Key_Event(132, qboolean(0), qboolean(1))
            } else if joyY < -0.5 {
                cl_joyscale_y.1 = Int32(min(abs(joyY) * 20, maxJoyValue))
                cl_joyscale_y.0 = 0
                Key_Event(132, qboolean(1), qboolean(1)) 
                Key_Event(133, qboolean(0), qboolean(1)) 
            }
            
            lastPanPoint = currentPoint
            
        case .ended, .cancelled, .failed:
            isPanning = false
            
            cl_joyscale_x.0 = 0
            cl_joyscale_x.1 = 0
            cl_joyscale_y.0 = 0
            cl_joyscale_y.1 = 0
            Key_Event(132, qboolean(0), qboolean(1))
            Key_Event(133, qboolean(0), qboolean(1))
            Key_Event(134, qboolean(0), qboolean(1))
            Key_Event(135, qboolean(0), qboolean(1))
            
        default:
            break
        }
    }
}



extension SDL_uikitviewcontroller: JoystickDelegate {
    
    func handleJoyStickPosition(x: CGFloat, y: CGFloat) {
        
    }

    func handleJoyStick(angle: CGFloat, displacement: CGFloat) {
        
        if displacement == 0 {
            Key_Event(119, qboolean(0), qboolean(1)) // W off
            Key_Event(115, qboolean(0), qboolean(1)) // S off
            Key_Event(97,  qboolean(0), qboolean(1)) // A off
            Key_Event(100, qboolean(0), qboolean(1)) // D off
            return
        }
        
        let radians = (180.0 - angle) * CGFloat.pi / 180.0
        let dx = sin(radians) * displacement
        let dy = cos(radians) * displacement
        
        
        Key_Event(119, dy < -0.35 ? qboolean(1) : qboolean(0), qboolean(1))
        Key_Event(115, dy > 0.35  ? qboolean(1) : qboolean(0), qboolean(1))
        
        
        Key_Event(97,  dx < -0.35 ? qboolean(1) : qboolean(0), qboolean(1))
        Key_Event(100, dx > 0.35  ? qboolean(1) : qboolean(0), qboolean(1))
    }
}

