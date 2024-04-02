import SwiftUI

struct PreparationView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Good Job! Now let's have some head exercises")
            Spacer()
            BottomNavigationView()
        }
        .font(.title)
        .fontWeight(.medium)
        .multilineTextAlignment(.center)
        .padding()
    }
}

#Preview {
    PreparationView()
}
