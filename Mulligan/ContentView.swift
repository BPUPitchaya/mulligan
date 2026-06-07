import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var videoCapture = VideoCaptureManager()
    @StateObject private var poseDetector = PoseDetector()
    @StateObject private var swingAnalyzer = SwingAnalyzer()
    @StateObject private var aiCoach = AICoach()
    
    @State private var selectedDevice: AVCaptureDevice?
    @State private var isRecording = false
    @State private var coachingFeedback = ""
    @State private var swingPlanePoints: [CGPoint] = []
    @State private var isDrawingPlane = false
    @State private var showPositioningGuide = true
    
    var body: some View {
        HSplitView {
            // Left panel - Video preview
            VStack {
                VideoPreviewView(
                    captureSession: videoCapture.captureSession,
                    poseLandmarks: poseDetector.detectedPose,
                    swingPlanePoints: $swingPlanePoints,
                    isDrawingPlane: $isDrawingPlane,
                    showPositioningGuide: $showPositioningGuide
                )
                .frame(minHeight: 400)
                
                // Controls
                HStack {
                    Picker("Camera", selection: $selectedDevice) {
                        Text("Select Camera").tag(nil as AVCaptureDevice?)
                        ForEach(videoCapture.availableDevices, id: \.uniqueID) { device in
                            Text(device.localizedName).tag(device as AVCaptureDevice?)
                        }
                    }
                    .frame(width: 200)
                    
                    Button(action: toggleRecording) {
                        Text(isRecording ? "Stop" : "Record")
                            .frame(width: 80)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Clear Plane") {
                        swingPlanePoints = []
                    }
                    .buttonStyle(.bordered)
                    
                    Toggle("Position Guide", isOn: $showPositioningGuide)
                        .toggleStyle(.switch)
                    
                    Button("Analyze Swing") {
                        Task {
                            await analyzeSwing()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(swingPlanePoints.count < 2)
                }
                .padding()
            }
            .frame(minWidth: 600)
            
            // Right panel - Coaching feedback
            CoachingView(feedback: coachingFeedback, metrics: swingAnalyzer.currentMetrics)
                .frame(minWidth: 300)
        }
        .frame(minWidth: 900, minHeight: 600)
        .task {
            // Connect pose detector to video capture via sample buffer handler
            videoCapture.setSampleBufferHandler { sampleBuffer in
                poseDetector.processSampleBuffer(sampleBuffer)
            }
            // Set initial selected device
            if selectedDevice == nil, let firstDevice = videoCapture.availableDevices.first {
                selectedDevice = firstDevice
            }
            await videoCapture.startSession()
            
            // Listen for view size changes
            NotificationCenter.default.addObserver(
                forName: .viewSizeChanged,
                object: nil,
                queue: .main
            ) { notification in
                if let size = notification.userInfo?["size"] as? CGSize {
                    swingAnalyzer.setViewSize(size)
                }
            }
        }
        .onChange(of: videoCapture.availableDevices) { _, _ in
            // Update selected device when devices change
            if selectedDevice == nil, let firstDevice = videoCapture.availableDevices.first {
                selectedDevice = firstDevice
            }
        }
        .onChange(of: selectedDevice) { _, newDevice in
            Task {
                await videoCapture.switchDevice(to: newDevice)
            }
        }
        .onChange(of: poseDetector.detectedPose) { _, newPose in
            if let pose = newPose {
                swingAnalyzer.updatePose(pose, swingPlane: swingPlanePoints)
            }
        }
    }
    
    private func toggleRecording() {
        isRecording.toggle()
        if isRecording {
            poseDetector.startDetection()
        } else {
            poseDetector.stopDetection()
        }
    }
    
    private func analyzeSwing() async {
        let metrics = swingAnalyzer.currentMetrics
        let feedback = await aiCoach.generateCoaching(metrics: metrics)
        coachingFeedback = feedback
    }
}
