import Foundation

@MainActor
class AICoach: ObservableObject {
    private let baseURL = "http://localhost:11434/api/chat"
    private let model = "llama3.2:3b"
    
    init() {
        // No API key needed for local Ollama
    }
    
    func generateCoaching(metrics: SwingMetrics) async -> String {
        let metricsDict = metrics.toDictionary()
        
        let prompt = """
        You are a professional golf swing coach. Analyze the following swing metrics and provide concise, actionable coaching feedback.
        
        Metrics:
        - Spine Angle: \(metricsDict["spine_angle"] as? Float ?? 0)°
        - Hip Rotation: \(metricsDict["hip_rotation"] as? Float ?? 0)°
        - Shoulder Tilt: \(metricsDict["shoulder_tilt"] as? Float ?? 0)°
        - Wrist Path Angle: \(metricsDict["wrist_path_angle"] as? Float ?? 0)°
        - Hand Plane Angle: \(metricsDict["hand_plane_angle"] as? Float ?? 0)°
        - Early Extension: \(metricsDict["early_extension"] as? Bool ?? false)
        
        Provide feedback in this format:
        1. One sentence summary of the main issue
        2. 2-3 specific actionable tips
        3. One drill to practice
        
        Keep it under 150 words total.
        """
        
        do {
            let feedback = try await requestCoaching(prompt: prompt)
            return feedback
        } catch {
            return generateLocalCoaching(metrics: metricsDict)
        }
    }
    
    private func generateLocalCoaching(metrics: [String: Any]) -> String {
        var issues: [String] = []
        var tips: [String] = []
        
        let spineAngle = metrics["spine_angle"] as? Float ?? 0
        let hipRotation = metrics["hip_rotation"] as? Float ?? 0
        let shoulderTilt = metrics["shoulder_tilt"] as? Float ?? 0
        let wristPathAngle = metrics["wrist_path_angle"] as? Float ?? 0
        let handPlaneAngle = metrics["hand_plane_angle"] as? Float ?? 0
        let earlyExtension = metrics["early_extension"] as? Bool ?? false
        
        // Analyze spine angle
        if spineAngle < 25 {
            issues.append("Spine angle too upright")
            tips.append("Tilt forward more from hips while maintaining a straight back")
        } else if spineAngle > 45 {
            issues.append("Spine angle too bent")
            tips.append("Stand taller with less forward bend")
        }
        
        // Analyze hip rotation
        if hipRotation < 30 {
            issues.append("Insufficient hip rotation")
            tips.append("Focus on rotating hips more during backswing")
        }
        
        // Analyze shoulder tilt
        if abs(shoulderTilt) > 30 {
            issues.append("Excessive shoulder tilt")
            tips.append("Keep shoulders more level at address")
        }
        
        // Analyze wrist path
        if abs(wristPathAngle) > 15 {
            issues.append("Wrist path deviation from plane")
            tips.append("Keep hands closer to your body on the swing plane")
        }
        
        // Analyze hand plane
        if abs(handPlaneAngle) > 10 {
            issues.append("Hand plane mismatch")
            tips.append("Match hand path to your intended swing plane")
        }
        
        // Early extension
        if earlyExtension {
            issues.append("Early extension detected")
            tips.append("Maintain spine angle through impact - don't stand up too early")
        }
        
        // Build feedback
        if issues.isEmpty {
            return "Great swing fundamentals! Your posture and rotation look solid. Continue focusing on consistency and tempo."
        }
        
 let feedback = """
Main issue: \(issues.first ?? "Check your swing mechanics")

Actionable tips:
\(tips.prefix(3).map { "• \($0)" }.joined(separator: "\n"))

Drill to practice: Practice slow-motion swings focusing on \(issues.first?.lowercased() ?? "your setup position") while maintaining balance.
"""
        
        return feedback
    }
    
    private func requestCoaching(prompt: String) async throws -> String {
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are a professional golf swing coach."],
                ["role": "user", "content": prompt]
            ],
            "stream": false
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AICoachError.requestFailed
        }
        
        if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = jsonResponse["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        
        throw AICoachError.invalidResponse
    }
}

enum AICoachError: Error {
    case invalidResponse
    case requestFailed
}
