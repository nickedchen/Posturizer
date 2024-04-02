import Charts
import SwiftUI

struct SummaryView: View {
    let score: Int

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(score > 0 ? "Smashing!" : "Better luck next time!")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                Text("Total Score: \(score)")
                    .font(.title)
            }
        }
    }
}
