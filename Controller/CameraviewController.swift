import AVFoundation
import UIKit
import Vision

// This part of the code was largely derived from https://developer.apple.com/videos/play/wwdc2021/10040/
// The controller is responsible for setting up the camera and detecting the user's face and facial landmarks.

class CameraViewController: UIViewController {

    // MARK: - Properties
    
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let captureSession = AVCaptureSession()
    private var sequenceHandler = VNSequenceRequestHandler()
    var orientationPublisher: ((CGFloat, CGFloat, CGFloat) -> Void)?
    var nosePointPublisher: ((CGPoint?) -> Void)?
    
    init(orientationPublisher: ((CGFloat, CGFloat, CGFloat) -> Void)? = nil, nosePointPublisher: ((CGPoint?) -> Void)? = nil) {
        self.orientationPublisher = orientationPublisher
        self.nosePointPublisher = nosePointPublisher
        super.init(nibName: nil, bundle: nil)
        setupCamera()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func setupCamera() {
        captureSession.sessionPreset = .high
        guard let captureDevice = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: captureDevice),
              captureSession.canAddInput(input)
        else {
            print("Failed to set up the camera.")
            return
        }
        captureSession.addInput(input)
        setupPreviewLayer()
        setupDataOutput()
    }
    
    private func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(previewLayer)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }
    
    private func setupDataOutput() {
        let dataOutput = AVCaptureVideoDataOutput()
        
        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
            dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            startCamera()
        } else {
            print("Cannot add data output to the session")
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        var requestOptions: [VNImageOption: Any] = [:]
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions[.cameraIntrinsics] = cameraIntrinsicData
        }
        
        let faceDetectionRequest = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let self = self else { return }
            if let error = error {
                print("Face detection error: \(error.localizedDescription)")
                return
            }
            guard let results = request.results as? [VNFaceObservation] else { return }
            self.detectFaceLandmarks(in: results)
        }
        
        do {
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: requestOptions)
            try imageRequestHandler.perform([faceDetectionRequest])
        } catch {
            print("Failed to perform face detection: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Face Angle and Landmark Detection
    
    private func detectFaceLandmarks(in faceObservations: [VNFaceObservation]) {
        for observation in faceObservations {
            let roll = observation.roll?.doubleValue ?? 0.0
            let pitch = observation.pitch?.doubleValue ?? 0.0
            let yaw = observation.yaw?.doubleValue ?? 0.0
            
            let rollInDegrees = roll * (180 / .pi)
            let pitchInDegrees = pitch * (180 / .pi)
            let yawInDegrees = yaw * (180 / .pi)
            
            orientationPublisher?(CGFloat(rollInDegrees), CGFloat(pitchInDegrees), CGFloat(yawInDegrees))
            
            if let nose = observation.landmarks?.nose {
                let nosePoints = nose.normalizedPoints.map { VNImagePointForNormalizedPoint($0, Int(self.previewLayer.bounds.width), Int(self.previewLayer.bounds.height)) }
                let averageNosePoint = nosePoints.average
                nosePointPublisher?(averageNosePoint)
            }
        }
    }
}

// MARK: - Camera Controls

extension CameraViewController {
    func startCamera() {
        DispatchQueue.main.async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopCamera() {
        DispatchQueue.main.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
}
