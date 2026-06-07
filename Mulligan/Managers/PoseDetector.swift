import Vision
import AVFoundation
import CoreImage
import Observation
import simd
import Combine

@Observable
@MainActor
class PoseDetector: NSObject, ObservableObject {
    var detectedPose: HumanBodyPose?
    private var poseRequest: VNDetectHumanBodyPoseRequest?
    private var visionQueue = DispatchQueue(label: "com.mulligan.visionQueue")
    private var isDetecting = false
    
    override init() {
        super.init()
        setupPoseRequest()
    }
    
    private func setupPoseRequest() {
        poseRequest = VNDetectHumanBodyPoseRequest()
        poseRequest?.revision = VNDetectHumanBodyPoseRequestRevision1
    }
    
    func startDetection() {
        isDetecting = true
    }
    
    func stopDetection() {
        isDetecting = false
    }
    
    func processSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard isDetecting,
              let request = poseRequest else { return }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        visionQueue.async { [weak self] in
            do {
                try handler.perform([request])
                
                if let observations = request.results?.first as? VNHumanBodyPoseObservation {
                    let pose = self?.convertToHumanBodyPose(observations)
                    DispatchQueue.main.async {
                        self?.detectedPose = pose
                    }
                }
            } catch {
                print("Vision error: \(error)")
            }
        }
    }
    
    nonisolated private func convertToHumanBodyPose(_ observation: VNHumanBodyPoseObservation) -> HumanBodyPose? {
        var joints: [JointName: simd_float2] = [:]
        
        let jointMapping: [VNHumanBodyPoseObservation.JointName: JointName] = [
            .nose: .nose,
            .leftEye: .leftEye,
            .rightEye: .rightEye,
            .leftEar: .leftEar,
            .rightEar: .rightEar,
            .leftShoulder: .leftShoulder,
            .rightShoulder: .rightShoulder,
            .leftElbow: .leftElbow,
            .rightElbow: .rightElbow,
            .leftWrist: .leftWrist,
            .rightWrist: .rightWrist,
            .leftHip: .leftHip,
            .rightHip: .rightHip,
            .leftKnee: .leftKnee,
            .rightKnee: .rightKnee,
            .leftAnkle: .leftAnkle,
            .rightAnkle: .rightAnkle
        ]
        
        for (vnJoint, jointName) in jointMapping {
            if let point = try? observation.recognizedPoint(vnJoint), point.confidence > 0.3 {
                joints[jointName] = simd_float2(Float(point.location.x), Float(point.location.y))
            }
        }
        
        return HumanBodyPose(joints: joints)
    }
}

struct HumanBodyPose: Equatable {
    var joints: [JointName: simd_float2]
    
    func getJoint(_ name: JointName) -> simd_float2? {
        return joints[name]
    }
    
    static func == (lhs: HumanBodyPose, rhs: HumanBodyPose) -> Bool {
        guard lhs.joints.count == rhs.joints.count else { return false }
        for (key, lhsValue) in lhs.joints {
            guard let rhsValue = rhs.joints[key] else { return false }
            if lhsValue.x != rhsValue.x || lhsValue.y != rhsValue.y {
                return false
            }
        }
        return true
    }
}

enum JointName {
    case nose
    case leftEye, rightEye
    case leftEar, rightEar
    case leftShoulder, rightShoulder
    case leftElbow, rightElbow
    case leftWrist, rightWrist
    case leftHip, rightHip
    case leftKnee, rightKnee
    case leftAnkle, rightAnkle
}
