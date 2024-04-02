import SwiftUI

struct AngleShape: Shape {
    var angle: Angle
    
    var animatableData: Angle {
        get { angle }
        set { angle = newValue }
    }
    
    var insets: UIEdgeInsets = .init(top: 100, left: 100, bottom: 100, right: 100)
    
    func path(in rect: CGRect) -> Path {
        let insetRect = rect.inset(by: insets)
   
        var path = Path()
        path.move(to: CGPoint(x: insetRect.minX, y: insetRect.maxY))
        path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.maxY))
        
        let hypotenuse: CGFloat = insetRect.maxX - insetRect.minX
        let adjacent = hypotenuse * cos(angle.radians)
        let opposite = hypotenuse * sin(angle.radians)
        let x = insetRect.minX + hypotenuse - adjacent
        let y = insetRect.minY + hypotenuse - opposite
        path.addLine(to: CGPoint(x: x, y: y))
        
        return path
    }
}

