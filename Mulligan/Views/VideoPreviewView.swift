import SwiftUI
import AVFoundation

struct VideoPreviewView: NSViewRepresentable {
    let captureSession: AVCaptureSession?
    let poseLandmarks: HumanBodyPose?
    @Binding var swingPlanePoints: [CGPoint]
    @Binding var isDrawingPlane: Bool
    
    func makeNSView(context: Context) -> VideoPreviewNSView {
        let view = VideoPreviewNSView()
        view.captureSession = captureSession
        view.poseLandmarks = poseLandmarks
        view.swingPlanePoints = swingPlanePoints
        view.isDrawingPlane = isDrawingPlane
        return view
    }
    
    func updateNSView(_ nsView: VideoPreviewNSView, context: Context) {
        nsView.poseLandmarks = poseLandmarks
        nsView.swingPlanePoints = swingPlanePoints
        nsView.isDrawingPlane = isDrawingPlane
    }
}

class VideoPreviewNSView: NSView {
    var captureSession: AVCaptureSession? {
        didSet {
            setupPreviewLayer()
        }
    }
    
    var poseLandmarks: HumanBodyPose? {
        didSet {
            needsDisplay = true
        }
    }
    
    var swingPlanePoints: [CGPoint] = [] {
        didSet {
            needsDisplay = true
        }
    }
    
    var isDrawingPlane: Bool = false
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }
    
    private func setupPreviewLayer() {
        previewLayer?.removeFromSuperlayer()
        
        guard let session = captureSession else { return }
        
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspect
        preview.frame = bounds
        layer?.addSublayer(preview)
        
        previewLayer = preview
    }
    
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        previewLayer?.frame = bounds
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // Draw swing plane
        if swingPlanePoints.count >= 2 {
            context.setStrokeColor(NSColor.red.cgColor)
            context.setLineWidth(2.0)
            context.setLineDash(phase: 0, lengths: [])
            
            context.move(to: swingPlanePoints[0])
            for point in swingPlanePoints.dropFirst() {
                context.addLine(to: point)
            }
            context.strokePath()
        }
        
        // Draw pose landmarks
        if let pose = poseLandmarks {
            drawPoseLandmarks(pose, in: context)
        }
    }
    
    private func drawPoseLandmarks(_ pose: HumanBodyPose, in context: CGContext) {
        let bounds = self.bounds
        let width = Float(bounds.width)
        let height = Float(bounds.height)
        
        // Convert normalized coordinates to view coordinates
        func convertPoint(_ point: simd_float2) -> CGPoint {
            return CGPoint(x: CGFloat(point.x * width), y: CGFloat((1 - point.y) * height))
        }
        
        // Define connections
        let connections: [(JointName, JointName)] = [
            (.nose, .leftEye),
            (.nose, .rightEye),
            (.leftEye, .leftEar),
            (.rightEye, .rightEar),
            (.leftShoulder, .rightShoulder),
            (.leftShoulder, .leftElbow),
            (.rightShoulder, .rightElbow),
            (.leftElbow, .leftWrist),
            (.rightElbow, .rightWrist),
            (.leftShoulder, .leftHip),
            (.rightShoulder, .rightHip),
            (.leftHip, .rightHip),
            (.leftHip, .leftKnee),
            (.rightHip, .rightKnee),
            (.leftKnee, .leftAnkle),
            (.rightKnee, .rightAnkle)
        ]
        
        // Draw connections
        context.setStrokeColor(NSColor.green.cgColor)
        context.setLineWidth(2.0)
        
        for (joint1, joint2) in connections {
            if let p1 = pose.getJoint(joint1), let p2 = pose.getJoint(joint2) {
                let point1 = convertPoint(p1)
                let point2 = convertPoint(p2)
                
                context.move(to: point1)
                context.addLine(to: point2)
                context.strokePath()
            }
        }
        
        // Draw joints
        context.setFillColor(NSColor.yellow.cgColor)
        let jointRadius: CGFloat = 4.0
        
        for joint in pose.joints.values {
            let point = convertPoint(joint)
            let rect = CGRect(x: point.x - jointRadius, y: point.y - jointRadius, 
                            width: jointRadius * 2, height: jointRadius * 2)
            context.fillEllipse(in: rect)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        guard isDrawingPlane else { return }
        let point = convert(event.locationInWindow, from: nil)
        swingPlanePoints.append(point)
    }
}
