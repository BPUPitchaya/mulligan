import AVFoundation
import SwiftUI
import Observation
import Combine

@Observable
@MainActor
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
        
        self.captureSession = session
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
    
    @MainActor
    func startSession() async {
        guard let session = captureSession else { 
            print("No capture session available")
            return 
        }
        
        print("Available devices: \(availableDevices.count)")
        print("Session inputs: \(session.inputs.count)")
        
        // Ensure we have an input before starting
        if session.inputs.isEmpty, let firstDevice = availableDevices.first {
            print("No input, adding first device: \(firstDevice.localizedName)")
            await switchDevice(to: firstDevice)
        }
        
        if !session.isRunning {
            session.startRunning()
            print("Session started, isRunning: \(session.isRunning)")
        } else {
            print("Session already running")
        }
    }
    
    func stopSession() {
        captureSession?.stopRunning()
    }
    
    @MainActor
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
                print("Successfully added device: \(newDevice.localizedName)")
            } else {
                print("Cannot add input to session")
            }
        } catch {
            print("Failed to add device input: \(error)")
        }
        
        if wasRunning {
            session.startRunning()
            print("Session started, isRunning: \(session.isRunning)")
        }
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let session = captureSession else { return nil }
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspect
        return previewLayer
    }
}
