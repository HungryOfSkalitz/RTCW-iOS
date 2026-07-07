import GameController
#if os(iOS)
import CoreMotion
#endif

class GameViewController: UIViewController {
    // ... (твои существующие переменные)
    var crouching = false

    // Переменные для камеры
    var cameraTouch: UITouch?
    var lastPoint: CGPoint = .zero

    // ... (твои @IBOutlet'ы)

    func handleMenuDragToPoint(point: CGPoint) {
        let deltaX:Int32 = Int32((point.x/self.view.bounds.size.width) * 640)
        let deltaY:Int32 = Int32((point.y/self.view.bounds.size.height) * 480)
        // qtrue — это qboolean(rawValue: 1)
        CL_MouseEvent(deltaX, deltaY, Sys_Milliseconds(), qboolean(rawValue: 1))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if Key_GetCatcher() & KEYCATCH_UI != 0 {
            for touch in touches { handleMenuDragToPoint(point: touch.location(in: self.view)) }
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
            for touch in touches { handleMenuDragToPoint(point: touch.location(in: self.view)) }
        } else {
            if let touch = cameraTouch, touches.contains(touch) {
                let currentPoint = touch.location(in: self.view)
                let dx = Int32((currentPoint.x - lastPoint.x) * 2.0)
                let dy = Int32((currentPoint.y - lastPoint.y) * 2.0)
                if dx != 0 || dy != 0 {
                    // qfalse — это qboolean(rawValue: 0)
                    CL_MouseEvent(dx, dy, Sys_Milliseconds(), qboolean(rawValue: 0))
                }
                lastPoint = currentPoint
            }
            super.touchesMoved(touches, with: event)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if Key_GetCatcher() & KEYCATCH_UI != 0 {
            // Используем Key_Event (с подчеркиванием), так как именно оно объявлено в joystick-коде
            Key_Event(Int32(K_MOUSE1.rawValue), qboolean(rawValue: 1), qboolean(rawValue: 0))
            Key_Event(Int32(K_MOUSE1.rawValue), qboolean(rawValue: 0), qboolean(rawValue: 0))
        } else {
            if let touch = cameraTouch, touches.contains(touch) { cameraTouch = nil }
            super.touchesEnded(touches, with: event)
        }
    }
}
