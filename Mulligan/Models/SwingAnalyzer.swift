import Foundation
import Observation
import Combine
import simd

@Observable
class SwingAnalyzer: ObservableObject {
    var currentMetrics: SwingMetrics = SwingMetrics()
    private var poseHistory: [HumanBodyPose] = []
    private let maxHistorySize = 60
    
    func updatePose(_ pose: HumanBodyPose, swingPlane: [CGPoint]) {
        poseHistory.append(pose)
        if poseHistory.count > maxHistorySize {
            poseHistory.removeFirst()
        }
        
        let previousPose = poseHistory.count > 1 ? poseHistory[poseHistory.count - 2] : nil
        
        // Convert swing plane to simd_float2
        let referencePlane: (simd_float2, simd_float2)? = swingPlane.count >= 2 ? 
            (simd_float2(Float(swingPlane[0].x), Float(swingPlane[0].y)),
             simd_float2(Float(swingPlane[1].x), Float(swingPlane[1].y))) : nil
        
        // Calculate metrics
        currentMetrics.spineAngle = GeometryEngine.calculateSpineAngle(pose: pose)
        currentMetrics.hipRotation = GeometryEngine.calculateHipRotation(pose: pose)
        currentMetrics.shoulderTilt = GeometryEngine.calculateShoulderTilt(pose: pose)
        
        if let refPlane = referencePlane {
            currentMetrics.wristPathAngle = GeometryEngine.calculateWristPathAngle(
                pose: pose, 
                referencePlane: refPlane
            )
        }
        
        currentMetrics.earlyExtension = GeometryEngine.detectEarlyExtension(
            pose: pose, 
            previousPose: previousPose
        )
        
        // Calculate hand plane angle
        if let leftWrist = pose.getJoint(.leftWrist),
           let rightWrist = pose.getJoint(.rightWrist),
           let refPlane = referencePlane {
            let handAngle = GeometryEngine.angleToReferenceLine(
                leftWrist, 
                rightWrist, 
                refPlane.0, 
                refPlane.1
            )
            currentMetrics.handPlaneAngle = handAngle
        }
    }
    
    func reset() {
        currentMetrics = SwingMetrics()
        poseHistory.removeAll()
    }
}

struct SwingMetrics {
    var spineAngle: Float?
    var hipRotation: Float?
    var shoulderTilt: Float?
    var wristPathAngle: Float?
    var handPlaneAngle: Float?
    var earlyExtension: Bool = false
    var timestamp: Date = Date()
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        if let spineAngle = spineAngle {
            dict["spine_angle"] = spineAngle
        }
        if let hipRotation = hipRotation {
            dict["hip_rotation"] = hipRotation
        }
        if let shoulderTilt = shoulderTilt {
            dict["shoulder_tilt"] = shoulderTilt
        }
        if let wristPathAngle = wristPathAngle {
            dict["wrist_path_angle"] = wristPathAngle
        }
        if let handPlaneAngle = handPlaneAngle {
            dict["hand_plane_angle"] = handPlaneAngle
        }
        dict["early_extension"] = earlyExtension
        
        return dict
    }
}
