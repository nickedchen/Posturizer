import SwiftUI

extension Collection where Element == CGPoint {
    var average: CGPoint? {
        guard !isEmpty else { return nil }
        let sum = reduce(.zero) { $0 + $1 }
        return CGPoint(x: sum.x / CGFloat(count), y: sum.y / CGFloat(count))
    }
}

extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}
