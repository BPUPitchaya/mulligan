import AVFoundation
import SwiftUI
import Observation
import Combine

@Observable
class VideoCaptureManager: NSObject, ObservableObject {
    var captureSession: AVCaptureSession?
    var availableDevices: [AVCaptureDevice] = []
    private var videoOutput: AVCaptureVideoDataOutput?
    private var deviceDiscoverySession: AVCaptureDevice.DiscoverySession?
    
    override init() {
        super.init()
        setupCaptureSession()
        discoverDevices()
    }
    
    private func setupCaptureSession() {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(nil, queue: DispatchQueue(label: "videoQueue"))
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        self.captureSession = session
        self.videoOutput = videoOutput
    }
    
    private func discoverDevices() {
        // Discover external cameras including Continuity Camera (iPhones)
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .external,
            .builtInWideAngleCamera,
            .continuityCamera,
            .deskViewCamera
        ]
        
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .unspecified
        )
        
        self.deviceDiscoverySession = discoverySession
        self.availableDevices = discoverySession.devices
        
        // Prefer external cameras (iPhones via Continuity Camera)
        availableDevices.sort { device1, device2 in
            if device1.deviceType == .external && device2.deviceType != .external {
                return true
            }
            return false
        }
    }
    
    @MainActor
    func startSession() async {
        guard let session = captureSession else { return }
        
        if !session.isRunning {
            session.startRunning()
        }
    }
    
    func stopSession() {
        captureSession?.stopRunning()
    }
    
    @MainActor
    func switchDevice(to device: AVCaptureDevice?) async {
        guard let session = captureSession,
              let newDevice = device else { return }
        
        session.stopRunning()
        
        // Remove current input
        session.inputs.forEach { session.removeInput($0) }
        
        do {
            let input = try AVCaptureDeviceInput(device: newDevice)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            print("Failed to add device input: \(error)")
        }
        
        session.startRunning()
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let session = captureSession else { return nil }
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspect
        return previewLayer
    }
}
