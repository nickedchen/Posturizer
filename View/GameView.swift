import SwiftUI

struct GameView: View {
    @StateObject var scoreManager = ScoreManager()

    var body: some View {
        ZStack(alignment: .top) {
            GameContainerView(scoreManager: scoreManager)
                .ignoresSafeArea()
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    HStack(spacing: 20) {
                        Text("Score")
                        Text("\(scoreManager.score)")
                            .foregroundStyle(.black)
                            .font(.largeTitle)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.accentColor)
                            )
                    }
                    .font(.largeTitle)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .padding()

                    Spacer()

                    Text("Tilt head up to jump, left and right to switch tracks")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                        .padding()
                        .background(.primary.opacity(0.6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding()
        }
    }
}

#Preview {
    GameView()
}
