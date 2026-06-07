import simd

struct GeometryEngine {
    
    /// Calculate angle between three points in degrees
    static func angleBetweenPoints(_ p1: simd_float2, _ vertex: simd_float2, _ p2: simd_float2) -> Float {
        let v1 = p1 - vertex
        let v2 = p2 - vertex
        
        let dotProduct = simd_dot(v1, v2)
        let magnitude1 = simd_length(v1)
        let magnitude2 = simd_length(v2)
        
        guard magnitude1 > 0 && magnitude2 > 0 else { return 0 }
        
        let cosAngle = dotProduct / (magnitude1 * magnitude2)
        let clampedCos = max(-1, min(1, cosAngle))
        let angleRadians = acos(clampedCos)
        
        return angleRadians * 180 / .pi
    }
    
    /// Calculate angle of a line segment relative to horizontal
    static func lineAngle(_ p1: simd_float2, _ p2: simd_float2) -> Float {
        let delta = p2 - p1
        let angleRadians = atan2(delta.y, delta.x)
        return angleRadians * 180 / .pi
    }
    
    /// Calculate distance between two points
    static func distance(_ p1: simd_float2, _ p2: simd_float2) -> Float {
        return simd_length(p2 - p1)
    }
    
    /// Calculate the angle between a line segment and a reference line
    static func angleToReferenceLine(_ segmentStart: simd_float2, _ segmentEnd: simd_float2, 
                                    _ refStart: simd_float2, _ refEnd: simd_float2) -> Float {
        let segmentAngle = lineAngle(segmentStart, segmentEnd)
        let refAngle = lineAngle(refStart, refEnd)
        
        var angleDiff = segmentAngle - refAngle
        
        // Normalize to -180 to 180
        while angleDiff > 180 { angleDiff -= 360 }
        while angleDiff < -180 { angleDiff += 360 }
        
        return angleDiff
    }
    
    /// Calculate spine angle (line from shoulders to hips)
    static func calculateSpineAngle(pose: HumanBodyPose) -> Float? {
        guard let leftShoulder = pose.getJoint(.leftShoulder),
              let rightShoulder = pose.getJoint(.rightShoulder),
              let leftHip = pose.getJoint(.leftHip),
              let rightHip = pose.getJoint(.rightHip) else {
            return nil
        }
        
        let shoulderMid = (leftShoulder + rightShoulder) / 2
        let hipMid = (leftHip + rightHip) / 2
        
        return lineAngle(hipMid, shoulderMid)
    }
    
    /// Calculate hip rotation angle
    static func calculateHipRotation(pose: HumanBodyPose) -> Float? {
        guard let leftShoulder = pose.getJoint(.leftShoulder),
              let rightShoulder = pose.getJoint(.rightShoulder),
              let leftHip = pose.getJoint(.leftHip),
              let rightHip = pose.getJoint(.rightHip) else {
            return nil
        }
        
        let shoulderAngle = lineAngle(leftShoulder, rightShoulder)
        let hipAngle = lineAngle(leftHip, rightHip)
        
        var rotation = shoulderAngle - hipAngle
        
        // Normalize
        while rotation > 180 { rotation -= 360 }
        while rotation < -180 { rotation += 360 }
        
        return rotation
    }
    
    /// Calculate wrist path angle relative to a reference plane
    static func calculateWristPathAngle(pose: HumanBodyPose, referencePlane: (simd_float2, simd_float2)) -> Float? {
        guard let wrist = pose.getJoint(.rightWrist) ?? pose.getJoint(.leftWrist),
              let shoulder = pose.getJoint(.rightShoulder) ?? pose.getJoint(.leftShoulder) else {
            return nil
        }
        
        return angleToReferenceLine(shoulder, wrist, referencePlane.0, referencePlane.1)
    }
    
    /// Check for early extension (hips moving toward target before impact)
    static func detectEarlyExtension(pose: HumanBodyPose, previousPose: HumanBodyPose?) -> Bool {
        guard let currentHipY = (pose.getJoint(.leftHip)?.y ?? pose.getJoint(.rightHip)?.y),
              let previousHipY = previousPose?.getJoint(.leftHip)?.y ?? previousPose?.getJoint(.rightHip)?.y else {
            return false
        }
        
        // In image coordinates, y increases downward
        // Early extension = hips moving up (decreasing y) too early
        return currentHipY < previousHipY
    }
    
    /// Calculate shoulder tilt angle
    static func calculateShoulderTilt(pose: HumanBodyPose) -> Float? {
        guard let leftShoulder = pose.getJoint(.leftShoulder),
              let rightShoulder = pose.getJoint(.rightShoulder) else {
            return nil
        }
        
        return lineAngle(leftShoulder, rightShoulder)
    }
}
