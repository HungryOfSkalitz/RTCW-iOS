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
    let motionManager: CMMotionManager = CMMotionManager()
    #endif
    
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
        argv.append("1")
        
        argv.append("+set")
        argv.append("in_joystickUseAnalog")
        argv.append("1")
        
        argv.append("+bind")
        argv.append("PAD0_RIGHTTRIGGER")
        argv.append("\"+attack\"")
        
        argv.append("+bind")
        argv.append("PAD0_LEFTSTICK_UP")
        argv.append("\"+forward\"")
        
        argv.append("+bind")
        argv.append("PAD0_LEFTSTICK_DOWN")
        argv.append("\"+back\"")
        
        argv.append("+bind")
        argv.append("PAD0_LEFTSTICK_LEFT")
        argv.append("\"+moveleft\"")
        
        argv.append("+bind")
        argv.append("PAD0_LEFTSTICK_RIGHT")
        argv.append("\"+moveright\"")
        
        argv.append("+bind")
        argv.append("PAD0_RIGHTSTICK_UP")
        argv.append("\"+lookup\"")
        
        argv.append("+bind")
        argv.append("PAD0_RIGHTSTICK_DOWN")
        argv.append("\"+lookdown\"")
        
        argv.append("+bind")
        argv.append("PAD0_RIGHTSTICK_LEFT")
        argv.append("\"+left\"")
        
        argv.append("+bind")
        argv.append("PAD0_RIGHTSTICK_RIGHT")
        argv.append("\"+right\"")
        
        argv.append("+bind")
        argv.append("PAD0_A")
        argv.append("\"+moveup\"")
        
        argv.append("+bind")
        argv.append("PAD0_LEFTSHOULDER")
        argv.append("\"weapnext\"")
        
        argv.append("+bind")
        argv.append("PAD0_RIGHTSHOULDER")
        argv.append("\"weapprev\"")
        
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
        if let js1 = self.joystick1 {
            js1.delegate = self
        }
        if self.defaults.integer(forKey: "tiltAiming") == 1 {
            self.motionManager.startDeviceMotionUpdates()
        }
        #endif
        }
    }
    
    func handleJoyStick(angle: CGFloat, displacement: CGFloat) {
        // Handled via position updates to engine commands
    }
    
    func handleJoyStickPosition(x: CGFloat, y: CGFloat) {
        let deadzone: CGFloat = 0.15
        let targetX = abs(x) > deadzone ? x : 0.0
        let targetY = abs(y) > deadzone ? y : 0.0
        
        if targetY > 0 {
            CL_KeyEvent(Int32(K_UPARROW.rawValue), qtrue, UInt32(Sys_Milliseconds()))
            CL_KeyEvent(Int32(K_DOWNARROW.rawValue), qfalse, UInt32(Sys_Milliseconds()))
        } else if targetY < 0 {
            CL_KeyEvent(Int32(K_DOWNARROW.rawValue), qtrue, UInt32(Sys_Milliseconds()))
            CL_KeyEvent(Int32(K_UPARROW.rawValue), qfalse, UInt32(Sys_Milliseconds()))
        } else {
            CL_KeyEvent(Int32(K_UPARROW.rawValue), qfalse, UInt32(Sys_Milliseconds()))
            CL_KeyEvent(Int32(K_DOWNARROW.rawValue), qfalse, UInt32(Sys_Milliseconds()))
        }
        
        if targetX > 0 {
            CL_KeyEvent(Int32(K_STRAFE_RIGHT.rawValue), qtrue, UInt32(Sys_Milliseconds()))
            CL_KeyEvent(Int32(K_STRAFE_LEFT.rawValue), qfalse, UInt32(Sys_Milliseconds()))
        let coof = (point.x - view.bounds.size.width / 2) * 1.3
                    point.x = (view.bounds.size.width / 2 + coof)
                }
                else {
                    let coof = (view.bounds.size.width / 2 - point.x) * 1.3;
                    point.x = (view.bounds.size.width / 2 - coof);
                }
            }
            
            mouseLocation.x = point.x * factor;
            mouseLocation.y = point.y * factor;
            
            deltaX = Int(roundf(Float((mouseLocation.x - GUIMouseLocation.x) * mouseScale.x)));
            deltaY = Int(roundf(Float((mouseLocation.y - GUIMouseLocation.y) * mouseScale.y)));
            
            GUIMouseLocation = mouseLocation;
            
            CL_MouseEvent(Int32(deltaX), Int32(deltaY), Sys_Milliseconds(), qtrue);
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if Key_GetCatcher() & KEYCATCH_UI != 0 {
            for touch in touches {
                handleMenuDragToPoint(point: touch.location(in: self.view))
            }
        } else {
            handleTouches(touches)
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
            // Reset mouse tracking state when finger lifts to avoid snap-turns
            GUIMouseLocation = CGPoint.zero
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
