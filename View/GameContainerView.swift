import Combine
import SceneKit
import SwiftUI

struct GameContainerView: UIViewControllerRepresentable {
    @ObservedObject var scoreManager: ScoreManager

    func makeUIViewController(context: Context) -> GameViewController {
        let controller = GameViewController()
        controller.scoreManager = scoreManager
        return controller
    }

    func updateUIViewController(_ uiViewController: GameViewController, context: Context) {}
}
