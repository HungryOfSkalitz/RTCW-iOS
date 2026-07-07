//
//  SDL2ViewController+Additions.swift
//  Quake2-iOS
//
//  Created by Tom Kidd on 1/28/19.
//

import UIKit

extension SDL_uikitviewcontroller {
    
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
    }
    
    var fireButton: UIButton {
        get { return Holder._fireButton }
        set(newValue) { Holder._fireButton = newValue }
    }
    
    var jumpButton: UIButton {
        get { return Holder._jumpButton }
        set(newValue) { Holder._jumpButton = newValue }
    }
    
    var useButton: UIButton {
        get { return Holder._useButton }
        set(newValue) { Holder._useButton = newValue }
    }
    
    var crouchButton: UIButton {
        get { return Holder._crouchButton }
        set(newValue) { Holder._crouchButton = newValue }
    }
    
    var joystickView: JoyStickView {
        get { return Holder._joystickView }
        set(newValue) { Holder._joystickView = newValue }
    }
    
    var f1Button: UIButton {
        get { return Holder._f1Button }
        set(newValue) { Holder._f1Button = newValue }
    }

    var prevWeaponButton: UIButton {
        get { return Holder._prevWeaponButton }
        set(newValue) { Holder._prevWeaponButton = newValue }
    }
    
    var nextWeaponButton: UIButton {
        get { return Holder._nextWeaponButton }
        set(newValue) { Holder._nextWeaponButton = newValue }
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
}

extension SDL_uikitviewcontroller: JoystickDelegate {
    
    func handleJoyStickPosition(x: CGFloat, y: CGFloat) {
       
    }

    func handleJoyStick(angle: CGFloat, displacement: CGFloat) {
        if displacement == 0 {
            Key_Event(119, qboolean(rawValue: 0), qboolean(rawValue: 1)) // off W
            Key_Event(115, qboolean(rawValue: 0), qboolean(rawValue: 1)) // off S
            Key_Event(97,  qboolean(rawValue: 0), qboolean(rawValue: 1)) // off A
            Key_Event(100, qboolean(rawValue: 0), qboolean(rawValue: 1)) // off D
            return
        }
        
        let radians = (180.0 - angle) * CGFloat.pi / 180.0
        let dx = sin(radians) * displacement
        let dy = cos(radians) * displacement
        
        Key_Event(119, dy < -0.35 ? qboolean(rawValue: 1) : qboolean(rawValue: 0), qboolean(rawValue: 1)) // W
        Key_Event(115, dy > 0.35  ? qboolean(rawValue: 1) : qboolean(rawValue: 0), qboolean(rawValue: 1)) // S
        Key_Event(97,  dx < -0.35 ? qboolean(rawValue: 1) : qboolean(rawValue: 0), qboolean(rawValue: 1)) // A
        Key_Event(100, dx > 0.35  ? qboolean(rawValue: 1) : qboolean(rawValue: 0), qboolean(rawValue: 1)) // D
    }
}
