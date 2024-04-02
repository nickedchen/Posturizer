import AVFoundation
import Combine
import SwiftUI
import UIKit
import Vision

class BodyPoseViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var humanObservation: VNHumanBodyPoseObservation?
    @Published var faceObservations: [VNFaceObservation] = []
    @Published var headPitch: Angle = .degrees(0)
    @Published var headYaw: Angle = .degrees(0)
    @Published var headRoll: Angle = .degrees(0)

    var captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
    private let confidenceThreshold: VNConfidence = 0.1
    
    override init() {
        super.init()
        requestCameraAccessAndSetupSession()
    }
    
    private func requestCameraAccessAndSetupSession() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard granted, AVCaptureDevice.authorizationStatus(for: .video) == .authorized else { return }
            self?.setupCaptureSession()
        }
    }
    
    private func setupCaptureSession() {
        guard configureCaptureSession() else {
            print("Failed to configure capture session")
            return
        }
        captureSession.commitConfiguration()
    }
    
    private func configureCaptureSession() -> Bool {
        captureSession.sessionPreset = .high
        guard let videoDevice = AVCaptureDevice.default(for: .video),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoDeviceInput),
              captureSession.canAddOutput(videoDataOutput) else { return false }
        
        captureSession.beginConfiguration()
        captureSession.addInput(videoDeviceInput)
        captureSession.addOutput(videoDataOutput)
        configureVideoOutput()
        return true
    }
    
    private func configureVideoOutput() {
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: Int32(kCVPixelFormatType_32BGRA))
        ]
    }
    
    func startSession() {
        captureSession.startRunning()
    }
    
    func stopSession() {
        captureSession.stopRunning()
    }
    
    private func processVideoFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let bodyPoseRequest = VNDetectHumanBodyPoseRequest { [weak self] request, _ in
            guard let self = self,
                  let results = request.results?.first as? VNHumanBodyPoseObservation else { return }
            DispatchQueue.main.async {
                self.updatePoseObservation(results)
            }
        }
        
        let faceDetectionRequest = VNDetectFaceRectanglesRequest { [weak self] request, _ in
            guard let self = self else { return }
            let faceObservations = request.results as? [VNFaceObservation] ?? []
            DispatchQueue.main.async {
                self.faceObservations = faceObservations
            }
        }
        
        performRequests([bodyPoseRequest, faceDetectionRequest], pixelBuffer: pixelBuffer)
    }
    
    private func performRequests(_ requests: [VNRequest], pixelBuffer: CVPixelBuffer) {
        do {
            try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:]).perform(requests)
        } catch {
            print("Failed to perform requests: \(error)")
        }
    }
    
    private func updatePoseObservation(_ bodyObservation: VNHumanBodyPoseObservation) {
        humanObservation = bodyObservation
        
        if let faceObservation = faceObservations.first(where: { $0.confidence > confidenceThreshold }) {
            let roll = faceObservation.roll?.doubleValue ?? 0
            let pitch = faceObservation.pitch?.doubleValue ?? 0
            let yaw = faceObservation.yaw?.doubleValue ?? 0
            
            DispatchQueue.main.async { [weak self] in
                self?.headRoll = Angle(degrees: roll * (180 / .pi))
                self?.headPitch = Angle(degrees: pitch * (180 / .pi))
                self?.headYaw = Angle(degrees: yaw * (180 / .pi))
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.headRoll = .degrees(0)
                self?.headPitch = .degrees(0)
                self?.headYaw = .degrees(0)
            }
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        processVideoFrame(sampleBuffer)
    }
    
    func createPreviewLayer(for view: UIView) {
        DispatchQueue.main.async {
            let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            previewLayer.frame = view.frame
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
        }
    }
}
