//
//  GameViewController.swift
//  Quake3-iOS
//
//  Created by Tom Kidd on 7/19/18.
//  Copyright © 2018 Tom Kidd. All rights reserved.
//

import GameController

#if os(iOS)
import CoreMotion
#endif

class GameViewController: UIViewController {

    var selectedMap = ""
    var selectedSavedGame = ""

    var selectedDifficulty = 0
    
    var gameInitialized = false
    
    var GUIMouseLocation = CGPoint(x: 0, y: 0)
    var GUIMouseOffset = CGSize(width: 0, height: 0)
    var mouseScale = CGPoint(x: 0, y: 0)
    let factor = UIScreen.main.scale
    var crouching = false

    // Переменные для трекинга правого пальца (свободный обзор камеры)
    var cameraTouch: UITouch?
    var lastCameraPoint = CGPoint.zero

    #if os(iOS)
    var joystick1: JoyStickView!
    var fireButton: UIButton!
    var jumpButton: UIButton!
    var useButton: UIButton!
    
    @IBOutlet weak var buttonStack: UIStackView!
    @IBOutlet weak var tildeButton: UIButton!
    @IBOutlet weak var expandButton: UIButton!
    @IBOutlet weak var escapeButton: UIButton!
    @IBOutlet weak var quickSaveButton: UIButton!
    @IBOutlet weak var quickLoadButton: UIButton!
    @IBOutlet weak var crouchButton: UIButton!
    var buttonStackExpanded = false
    #endif
    
    let defaults = UserDefaults()
    
    @IBOutlet weak var nextWeaponButton: UIButton!
    @IBOutlet weak var prevWeaponButton: UIButton!
    
    #if os(iOS)
    let motionManager = CMMotionManager()
    #endif
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func handleTouches(_ touches: Set<UITouch>) {
        if Key_GetCatcher() & KEYCATCH_UI != 0 {
            for touch in touches {
                handleMenuDragToPoint(point: touch.location(in: self.view))
            }
        }
    }
    

    var cameraTouch: UITouch?
    var lastPoint: CGPoint = .zero

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if Key_GetCatcher() & KEYCATCH_UI != 0 {
            for touch in touches {
                handleMenuDragToPoint(point: touch.location(in: self.view))
            }
        } else {
            
            for touch in touches {
                let point = touch.location(in: self.view)
                if point.x > self.view.bounds.size.width / 2 {
                    cameraTouch = touch
                    lastPoint = point
                }
            }
            super.touchesBegan(touches, with: event)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if Key_GetCatcher() & KEYCATCH_UI != 0 {
            for touch in touches {
                handleMenuDragToPoint(point: touch.location(in: self.view))
            }
        } else {
            
            if let touch = cameraTouch, touches.contains(touch) {
                let currentPoint = touch.location(in: self.view)
                let dx = Int32((currentPoint.x - lastPoint.x) * 2.0)
                let dy = Int32((currentPoint.y - lastPoint.y) * 2.0)
                
                if dx != 0 || dy != 0 {
                    
                    CL_MouseEvent(dx, dy, Sys_Milliseconds(), 0) 
                }
                lastPoint = currentPoint
            }
            super.touchesMoved(touches, with: event)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if Key_GetCatcher() & KEYCATCH_UI != 0 {
            KeyEvent(key: K_MOUSE1, down: true)
            KeyEvent(key: K_MOUSE1, down: false)
        } else {
            if let touch = cameraTouch, touches.contains(touch) {
                cameraTouch = nil
            }
            super.touchesEnded(touches, with: event)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = cameraTouch, touches.contains(touch) {
            cameraTouch = nil
        }
        super.touchesCancelled(touches, with: event)
    }
    
    func handleMenuDragToPoint(point: CGPoint) {
        let deltaX:Int32 = Int32((point.x/self.view.bounds.size.width) * 640)
        let deltaY:Int32 = Int32((point.y/self.view.bounds.size.height) * 480)
        CL_MouseEvent(deltaX, deltaY, Sys_Milliseconds(), qtrue)
    }
}
