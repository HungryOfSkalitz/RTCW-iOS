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

class GameViewController: UIViewController, JoystickDelegate {

    var selectedMap = ""
    var selectedSavedGame = ""

    var selectedDifficulty = 0
    
    var gameInitialized = false
    
    var GUIMouseLocation = CGPoint(x: 0, y: 0)
    var GUIMouseOffset = CGSize(width: 0, height: 0)
    var mouseScale = CGPoint(x: 0, y: 0)
    let factor = UIScreen.main.scale
    var crouching = false

    #if os(iOS)
    @IBOutlet weak var joystick1: JoyStickView!
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
    let motionManager: CMMotionManager = CMMotionManager()
    #endif
    
    var lastTouchPoints = [UITouch: CGPoint]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (UIApplication.shared.delegate as! AppDelegate).gameViewControllerView = self.view
        
        var size = view.layer.bounds.size;
        size.width = CGFloat(roundf(Float(size.width * factor)))
        size.height = CGFloat(roundf(Float(size.height * factor)))
        if (size.width > size.height) {
            GUIMouseOffset.width = 0
            GUIMouseOffset.height = 0;
            mouseScale.x = 640 / size.width;
            mouseScale.y = 480 / size.height;
        }
        else {
            let aspect = size.height / size.width;
            
            GUIMouseOffset.width = CGFloat(-roundf(Float((480 * aspect - 640) / 2.0)));
            GUIMouseOffset.height = 0;
            mouseScale.x = (480 * aspect) / size.height;
            mouseScale.y = 480 / size.width;
        }
        
        #if os(iOS)
        self.navigationController?.navigationItem.backBarButtonItem?.isEnabled = false
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        if joystick1 != nil {
            joystick1.delegate = self
        }
        #endif
        
        #if os(tvOS)
        let menuPressRecognizer = UITapGestureRecognizer()
        menuPressRecognizer.addTarget(self, action: #selector(GameViewController.menuButtonAction))
        menuPressRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.menu.rawValue)]
        
        self.view.addGestureRecognizer(menuPressRecognizer)
        #endif
        
        #if os(tvOS)
        let documentsDir = try! FileManager().url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true).path
        #else
        let documentsDir = try! FileManager().url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).path
        #endif
        
        Sys_SetHomeDir(documentsDir)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {

        var argv: [String?] = [Bundle.main.resourcePath! + "/rtcw", "+set", "com_basegame", "Main"]

        if !self.selectedMap.isEmpty {
            argv.append("+spmap")
            argv.append("cutscene1")
            argv.append("+g_spSkill")
            argv.append(String(self.selectedDifficulty))
        }

        if !self.selectedSavedGame.isEmpty {
            argv.append("+loadgame")
            argv.append(self.selectedSavedGame)
        }
        
        let screenBounds = UIScreen.main.bounds
        let screenScale:CGFloat = UIScreen.main.scale
        let screenSize = CGSize(width: screenBounds.size.width * screenScale, height: screenBounds.size.height * screenScale)

        argv.append("+set")
        argv.append("r_mode")
        argv.append("-1")

        argv.append("+set")
        argv.append("r_customwidth")
        argv.append("\(screenSize.width)")

        argv.append("+set")
        argv.append("r_customheight")
        argv.append("\(screenSize.height)")

        argv.append("+set")
        argv.append("s_sdlSpeed")
        argv.append("44100")
        
        argv.append("+set")
        argv.append("r_useHiDPI")
        argv.append("1")
        
        argv.append("+set")
        argv.append("in_joystick")
        argv.append("0")
        
        argv.append("+set")
        argv.append("in_joystickUseAnalog")
        argv.append("0")
        
        #if DEBUG
        argv.append("+set")
        argv.append("developer")
        argv.append("1")
        #endif
            
        argv.append(nil)
        
        let argc:Int32 = Int32(argv.count - 1)
        var cargs = argv.map { $0.flatMap { UnsafeMutablePointer<Int8>(strdup($0)) } }
        
        Sys_Startup(argc, &cargs)
        
        for ptr in cargs { free(UnsafeMutablePointer(mutating: ptr)) }
        
            self.gameInitialized = true
        
        #if os(iOS)
        if self.defaults.integer(forKey: "tiltAiming") == 1 {
            self.motionManager.startDeviceMotionUpdates()
        }
        #endif
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if joystick1 != nil {
            joystick1.delegate = self
        }
    }
    
    func handleJoyStick(angle: CGFloat, displacement: CGFloat) {
        if displacement == 0 {
            CL_KeyEvent(Int32(119), qfalse, UInt32(Sys_Milliseconds())) // W
            CL_KeyEvent(Int32(115), qfalse, UInt32(Sys_Milliseconds())) // S
            CL_KeyEvent(Int32(97), qfalse, UInt32(Sys_Milliseconds()))  // A
            CL_KeyEvent(Int32(100), qfalse, UInt32(Sys_Milliseconds())) // D
            return
        }
        
        let radians = (180.0 - angle) * CGFloat.pi / 180.0
        let dx = sin(radians) * displacement
        let dy = cos(radians) * displacement
        
        CL_KeyEvent(Int32(119), dy > 0.3 ? qtrue : qfalse, UInt32(Sys_Milliseconds()))
        CL_KeyEvent(Int32(115), dy < -0.3 ? qtrue : qfalse, UInt32(Sys_Milliseconds()))
        CL_KeyEvent(Int32(97), dx < -0.3 ? qtrue : qfalse, UInt32(Sys_Milliseconds()))
        CL_KeyEvent(Int32(100), dx > 0.3 ? qtrue : qfalse, UInt32(Sys_Milliseconds()))
    }
    
    func handleJoyStickPosition(x: CGFloat, y: CGFloat) {
    }
    
    @objc func menuButtonAction() {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func firePressed(sender: UIButton!) {
        KeyEvent(key: K_MOUSE1, down: true)
    }
    
    @objc func fireReleased(sender: UIButton!) {
        KeyEvent(key: K_MOUSE1, down: false)
    }
    
    @objc func jumpPressed(sender: UIButton!) {
        KeyEvent(key: K_SPACE, down: true)
    }
    
    @objc func jumpReleased(sender: UIButton!) {
        KeyEvent(key: K_SPACE, down: false)
    }
    
    @objc func usePressed(sender: UIButton!) {
        CL_KeyEvent(Int32(102), qtrue, UInt32(Sys_Milliseconds()))
    }
    
    @objc func useReleased(sender: UIButton!) {
        CL_KeyEvent(Int32(102), qfalse, UInt32(Sys_Milliseconds()))
    }
    
    @IBAction func crouch(_ sender: UIButton) {
        crouching = !crouching
        CL_KeyEvent(Int32(99), crouching ? qtrue : qfalse, UInt32(Sys_Milliseconds()))
    }
    
    #if os(iOS)
    @IBAction func expand(_ sender: Any) {
        buttonStackExpanded = !buttonStackExpanded
        
        UIView.animate(withDuration: 0.5) {
            self.expandButton.setTitle(self.buttonStackExpanded ? "<" : ">", for: .normal)
            self.escapeButton.isHidden = !self.buttonStackExpanded
            self.escapeButton.alpha = self.buttonStackExpanded ? 1 : 0
            self.tildeButton.isHidden = !self.buttonStackExpanded
            self.tildeButton.alpha = self.buttonStackExpanded ? 1 : 0
            self.quickLoadButton.isHidden = !self.buttonStackExpanded
            self.quickLoadButton.alpha = self.buttonStackExpanded ? 1 : 0
            self.quickSaveButton.isHidden = !self.buttonStackExpanded
            self.quickSaveButton.alpha = self.buttonStackExpanded ? 1 : 0
        }
        
    }
    #endif
    
    @IBAction func tilde(_ sender: UIButton) {
        CL_KeyEvent(Int32(K_CONSOLE.rawValue), qtrue, UInt32(Sys_Milliseconds()))
        CL_KeyEvent(Int32(K_CONSOLE.rawValue), qfalse, UInt32(Sys_Milliseconds()))
    }
    
    @IBAction func escape(_ sender: UIButton) {
        CL_KeyEvent(Int32(K_ESCAPE.rawValue), qtrue, UInt32(Sys_Milliseconds()))
        CL_KeyEvent(Int32(K_ESCAPE.rawValue), qfalse, UInt32(Sys_Milliseconds()))
    }
    
    @IBAction func quickSave(_ sender: UIButton) {
    CL_KeyEvent(Int32(K_F5.rawValue), qtrue, UInt32(Sys_Milliseconds()))
        CL_KeyEvent(Int32(K_F5.rawValue), qfalse, UInt32(Sys_Milliseconds()))
    }
    
    @IBAction func quickLoad(_ sender: UIButton) {
        CL_KeyEvent(Int32(K_F9.rawValue), qtrue, UInt32(Sys_Milliseconds()))
        CL_KeyEvent(Int32(K_F9.rawValue), qfalse, UInt32(Sys_Milliseconds()))
    }
    

    @IBAction func nextWeapon(sender: UIButton) {
        CL_KeyEvent(Int32(K_MWHEELUP.rawValue), qtrue, UInt32(Sys_Milliseconds()))
        CL_KeyEvent(Int32(K_MWHEELUP.rawValue), qfalse, UInt32(Sys_Milliseconds()))
    }
    
    @IBAction func prevWeapon(sender: UIButton) {
        CL_KeyEvent(Int32(K_MWHEELDOWN.rawValue), qtrue, UInt32(Sys_Milliseconds()))
        CL_KeyEvent(Int32(K_MWHEELDOWN.rawValue), qfalse, UInt32(Sys_Milliseconds()))
    }
    
    func handleTouches(_ touches: Set<UITouch>) {
        for touch in touches {
            let point = touch.location(in: view)
            
            if joystick1 != nil && joystick1.frame.contains(point) {
                continue
            }
            
            guard let lastPoint = lastTouchPoints[touch] else { continue }
            
            let deltaX = Int32((point.x - lastPoint.x) * mouseScale.x * 4.0)
            let deltaY = Int32((point.y - lastPoint.y) * mouseScale.y * 4.0)
            
            CL_MouseEvent(deltaX, deltaY, Sys_Milliseconds(), qfalse)
            lastTouchPoints[touch] = point
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if Key_GetCatcher() & KEYCATCH_UI != 0 {
            for touch in touches {
                handleMenuDragToPoint(point: touch.location(in: self.view))
            }
        } else {
            for touch in touches {
                let point = touch.location(in: view)
                if joystick1 != nil && joystick1.frame.contains(point) {
                    continue
                }
                lastTouchPoints[touch] = point
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if Key_GetCatcher() & KEYCATCH_UI != 0 {
            for touch in touches {
                handleMenuDragToPoint(point: touch.location(in: self.view))
            }
        } else {
            handleTouches(touches)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if Key_GetCatcher() & KEYCATCH_UI != 0 {
            KeyEvent(key: K_MOUSE1, down: true)
            KeyEvent(key: K_MOUSE1, down: false)
        } else {
            for touch in touches {
                lastTouchPoints.removeValue(forKey: touch)
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            lastTouchPoints.removeValue(forKey: touch)
        }
    }
    
    func handleMenuDragToPoint(point: CGPoint) {
        let deltaX:Int32 = Int32((point.x/self.view.bounds.size.width) * 640)
        let deltaY:Int32 = Int32((point.y/self.view.bounds.size.height) * 480)
        CL_MouseEvent(deltaX, deltaY, Sys_Milliseconds(), qtrue)
    }
    
    func KeyEvent(key: keyNum_t, down: Bool) {
          CL_KeyEvent(Int32(key.rawValue), qboolean(rawValue: down ? 1 : 0), UInt32(Sys_Milliseconds()))
    }

}
