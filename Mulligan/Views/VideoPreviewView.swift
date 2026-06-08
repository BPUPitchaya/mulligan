import SwiftUI
import AVFoundation

extension Notification.Name {
    static let viewSizeChanged = Notification.Name("viewSizeChanged")
}

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
        
        // Update swing analyzer with current view size
        if let contentView = superview as? NSView,
           let hostingView = contentView.superview,
           let window = hostingView.window {
            // Notify ContentView of size change
            NotificationCenter.default.post(name: .viewSizeChanged, object: nil, userInfo: ["size": bounds.size])
        }
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
        
        // Draw golfer silhouette (ideal address position)
        drawGolferSilhouette(in: context, centerX: centerX, centerY: centerY, guideWidth: guideWidth, guideHeight: guideHeight)
        
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
    
    private func drawGolferSilhouette(in context: CGContext, centerX: CGFloat, centerY: CGFloat, guideWidth: CGFloat, guideHeight: CGFloat) {
        // Golfer silhouette points (ideal address position - side view)
        let scale = guideWidth * 0.4
        let offsetX = centerX
        let offsetY = centerY - guideHeight * 0.1
        
        // Head
        let headCenter = CGPoint(x: offsetX, y: offsetY - scale * 0.4)
        let headRadius = scale * 0.08
        
        context.setStrokeColor(NSColor.white.withAlphaComponent(0.4).cgColor)
        context.setLineWidth(2.0)
        context.setLineDash(phase: 0, lengths: [])
        
        context.addEllipse(in: CGRect(x: headCenter.x - headRadius, y: headCenter.y - headRadius,
                                     width: headRadius * 2, height: headRadius * 2))
        context.strokePath()
        
        // Body lines (stick figure in address position)
        let neck = CGPoint(x: offsetX, y: offsetY - scale * 0.3)
        let shoulder = CGPoint(x: offsetX, y: offsetY - scale * 0.15)
        let hip = CGPoint(x: offsetX, y: offsetY + scale * 0.15)
        let knee = CGPoint(x: offsetX - scale * 0.05, y: offsetY + scale * 0.4)
        let ankle = CGPoint(x: offsetX - scale * 0.02, y: offsetY + scale * 0.65)
        
        // Spine (tilted forward)
        context.move(to: neck)
        context.addLine(to: shoulder)
        context.addLine(to: hip)
        context.strokePath()
        
        // Legs
        context.move(to: hip)
        context.addLine(to: knee)
        context.addLine(to: ankle)
        context.strokePath()
        
        // Arms (hanging down in address position)
        let leftShoulder = CGPoint(x: offsetX - scale * 0.12, y: shoulder.y)
        let rightShoulder = CGPoint(x: offsetX + scale * 0.12, y: shoulder.y)
        let leftElbow = CGPoint(x: offsetX - scale * 0.15, y: offsetY + scale * 0.1)
        let rightElbow = CGPoint(x: offsetX + scale * 0.15, y: offsetY + scale * 0.1)
        let leftWrist = CGPoint(x: offsetX - scale * 0.18, y: offsetY + scale * 0.2)
        let rightWrist = CGPoint(x: offsetX + scale * 0.18, y: offsetY + scale * 0.2)
        
        // Shoulder line
        context.move(to: leftShoulder)
        context.addLine(to: rightShoulder)
        context.strokePath()
        
        // Left arm
        context.move(to: leftShoulder)
        context.addLine(to: leftElbow)
        context.addLine(to: leftWrist)
        context.strokePath()
        
        // Right arm
        context.move(to: rightShoulder)
        context.addLine(to: rightElbow)
        context.addLine(to: rightWrist)
        context.strokePath()
        
        // Club shaft indication
        let clubTop = CGPoint(x: offsetX + scale * 0.18, y: offsetY + scale * 0.2)
        let clubBottom = CGPoint(x: offsetX + scale * 0.1, y: offsetY + scale * 0.5)
        
        context.setStrokeColor(NSColor.systemYellow.withAlphaComponent(0.5).cgColor)
        context.setLineWidth(3.0)
        context.move(to: clubTop)
        context.addLine(to: clubBottom)
        context.strokePath()
        
        // Draw joint markers
        context.setFillColor(NSColor.white.withAlphaComponent(0.6).cgColor)
        let jointRadius: CGFloat = 3.0
        
        let joints = [headCenter, neck, shoulder, hip, knee, ankle, leftShoulder, rightShoulder,
                     leftElbow, rightElbow, leftWrist, rightWrist]
        
        for joint in joints {
            context.fillEllipse(in: CGRect(x: joint.x - jointRadius, y: joint.y - jointRadius,
                                          width: jointRadius * 2, height: jointRadius * 2))
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
