import SwiftUI

struct WedgeShape: Shape {
    var angle: Angle
    
    var animatableData: Angle {
        get { angle }
        set { angle = newValue }
    }
    
    var insets: UIEdgeInsets = .init(top: 100, left: 100, bottom: 100, right: 100)
    
    func path(in rect: CGRect) -> Path {
        let insetRect = rect.inset(by: insets)

        var path = Path()
        
        let center = CGPoint(x: insetRect.maxX, y: insetRect.maxY)
        let radius: CGFloat = insetRect.maxX - insetRect.minX
        
        let startAngle = Angle.degrees(-180)
        let endAngle = startAngle + angle
        
        path.addArc(center: center, radius: radius - 20, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addArc(center: center, radius: radius - 40, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()
        
        return path
    }
}
