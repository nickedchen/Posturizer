import SwiftUI
import UIKit

struct CameraView: UIViewRepresentable {
    @ObservedObject var viewModel: BodyPoseViewModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        viewModel.createPreviewLayer(for: view)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
    
    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
       
    }
}
