import SwiftUI

extension Angle: VectorArithmetic {
    public mutating func scale(by rhs: Double) {
        self = .radians(self.radians * rhs)
    }
    
    public var magnitudeSquared: Double {
        self.radians * self.radians
    }
}

extension Angle: AdditiveArithmetic {
    public static var zero: Self { .radians(0) }
    
    public static func + (lhs: Self, rhs: Self) -> Self {
        .radians(lhs.radians + rhs.radians)
    }
    
    public static func += (lhs: inout Self, rhs: Self) {
        lhs = .radians(lhs.radians + rhs.radians)
    }
    
    public static func - (lhs: Self, rhs: Self) -> Self {
        .radians(lhs.radians - rhs.radians)
    }
    
    public static func -= (lhs: inout Self, rhs: Self) {
        lhs = .radians(lhs.radians - rhs.radians)
    }
}
