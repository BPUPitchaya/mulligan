import AVFoundation
import SwiftUI
import Observation
import Combine

@Observable
@MainActor
class VideoCaptureManager: NSObject, ObservableObject, @preconcurrency AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureSession: AVCaptureSession?
    var availableDevices: [AVCaptureDevice] = []
    private var videoOutput: AVCaptureVideoDataOutput?
    private var deviceDiscoverySession: AVCaptureDevice.DiscoverySession?
    private var onSampleBuffer: ((CMSampleBuffer) -> Void)?
    
    override init() {
        super.init()
        setupCaptureSession()
        discoverDevices()
    }
    
    func setSampleBufferHandler(_ handler: @escaping (CMSampleBuffer) -> Void) {
        self.onSampleBuffer = handler
    }
    
    private func setupCaptureSession() {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        
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
            .continuityCamera
        ]
        
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .unspecified
        )
        
        self.deviceDiscoverySession = discoverySession
        self.availableDevices = discoverySession.devices
        
        // If no external cameras, fall back to built-in
        if availableDevices.isEmpty {
            let builtInDiscovery = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: .unspecified
            )
            self.availableDevices = builtInDiscovery.devices
        }
        
        // Add first available device as initial input
        if let firstDevice = availableDevices.first {
            Task {
                await switchDevice(to: firstDevice)
            }
        }
    }
    
    func startSession() async {
        guard let session = captureSession else { return }
        
        // Ensure we have an input before starting
        if session.inputs.isEmpty, let firstDevice = availableDevices.first {
            await switchDevice(to: firstDevice)
        }
        
        if !session.isRunning {
            session.startRunning()
        }
    }
    
    func stopSession() {
        captureSession?.stopRunning()
    }
    
    func switchDevice(to device: AVCaptureDevice?) async {
        guard let session = captureSession,
              let newDevice = device else { return }
        
        let wasRunning = session.isRunning
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
        
        if wasRunning {
            session.startRunning()
        }
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let session = captureSession else { return nil }
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspect
        return previewLayer
    }
    
    func handleSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        onSampleBuffer?(sampleBuffer)
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        handleSampleBuffer(sampleBuffer)
    }
}
