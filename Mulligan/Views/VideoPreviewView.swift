import SwiftUI
import AVFoundation

struct VideoPreviewView: NSViewRepresentable {
    let captureSession: AVCaptureSession?
    let poseLandmarks: HumanBodyPose?
    @Binding var swingPlanePoints: [CGPoint]
    @Binding var isDrawingPlane: Bool
    @Binding var showPositioningGuide: Bool
    
    func makeNSView(context: Context) -> VideoPreviewNSView {
        let view = VideoPreviewNSView()
        view.captureSession = captureSession
        view.poseLandmarks = poseLandmarks
        view.swingPlanePoints = swingPlanePoints
        view.isDrawingPlane = isDrawingPlane
        view.showPositioningGuide = showPositioningGuide
        return view
    }
    
    func updateNSView(_ nsView: VideoPreviewNSView, context: Context) {
        nsView.captureSession = captureSession
        nsView.poseLandmarks = poseLandmarks
        nsView.swingPlanePoints = swingPlanePoints
        nsView.isDrawingPlane = isDrawingPlane
        nsView.showPositioningGuide = showPositioningGuide
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
    
    var showPositioningGuide: Bool = false {
        didSet {
            needsDisplay = true
        }
    }
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = CALayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer = CALayer()
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
    
    override func layout() {
        super.layout()
        previewLayer?.frame = bounds
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // Draw positioning guide
        if showPositioningGuide {
            drawPositioningGuide(in: context)
        }
        
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
    
    private func drawPositioningGuide(in context: CGContext) {
        let bounds = self.bounds
        let centerX = bounds.width / 2
        let centerY = bounds.height / 2
        
        // Draw semi-transparent background area for ideal positioning
        let guideWidth = bounds.width * 0.6
        let guideHeight = bounds.height * 0.7
        let guideRect = CGRect(
            x: centerX - guideWidth / 2,
            y: centerY - guideHeight / 2,
            width: guideWidth,
            height: guideHeight
        )
        
        context.setFillColor(NSColor.systemGreen.withAlphaComponent(0.1).cgColor)
        context.fill(guideRect)
        
        // Draw border
        context.setStrokeColor(NSColor.systemGreen.withAlphaComponent(0.5).cgColor)
        context.setLineWidth(2.0)
        context.setLineDash(phase: 0, lengths: [5, 5])
        context.stroke(guideRect)
        
        // Draw center line (ball position reference)
        context.setStrokeColor(NSColor.white.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(1.0)
        context.setLineDash(phase: 0, lengths: [])
        
        let ballY = centerY + guideHeight * 0.3
        context.move(to: CGPoint(x: centerX - guideWidth / 2, y: ballY))
        context.addLine(to: CGPoint(x: centerX + guideWidth / 2, y: ballY))
        context.strokePath()
        
        // Draw shoulder line reference
        let shoulderY = centerY - guideHeight * 0.2
        context.setStrokeColor(NSColor.systemBlue.withAlphaComponent(0.3).cgColor)
        context.setLineDash(phase: 0, lengths: [3, 3])
        context.move(to: CGPoint(x: centerX - guideWidth * 0.3, y: shoulderY))
        context.addLine(to: CGPoint(x: centerX + guideWidth * 0.3, y: shoulderY))
        context.strokePath()
        
        // Draw label
        let label = "Stand Here"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.7)
        ]
        let labelSize = label.size(withAttributes: attributes)
        let labelRect = CGRect(
            x: centerX - labelSize.width / 2,
            y: centerY - guideHeight / 2 - 25,
            width: labelSize.width,
            height: labelSize.height
        )
        label.draw(in: labelRect, withAttributes: attributes)
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
