import SwiftUI

struct AngleView: View {
    var angle: Angle
    var rotate90Degrees: Bool 

    var body: some View {
        VStack {
            ZStack {
                WedgeShape(angle: angle)
                    .fill(.thickMaterial)
                AngleShape(angle: angle)
                    .stroke(.foreground, style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
            }
            .rotationEffect(rotate90Degrees ? .degrees(90) : .degrees(0))
            .offset(x: rotate90Degrees ? 50 : 0)
            .animation(.default, value: angle)
        }
    }
}
