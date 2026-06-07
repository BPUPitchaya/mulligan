import SwiftUI

struct CoachingView: View {
    let feedback: String
    let metrics: SwingMetrics
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("AI Coach")
                    .font(.title)
                    .fontWeight(.bold)
                
                Divider()
                
                // Metrics Display
                VStack(alignment: .leading, spacing: 12) {
                    Text("Swing Metrics")
                        .font(.headline)
                    
                    MetricRow(label: "Spine Angle", value: metrics.spineAngle, unit: "°")
                    MetricRow(label: "Hip Rotation", value: metrics.hipRotation, unit: "°")
                    MetricRow(label: "Shoulder Tilt", value: metrics.shoulderTilt, unit: "°")
                    MetricRow(label: "Wrist Path Angle", value: metrics.wristPathAngle, unit: "°")
                    MetricRow(label: "Hand Plane Angle", value: metrics.handPlaneAngle, unit: "°")
                    
                    HStack {
                        Text("Early Extension:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(metrics.earlyExtension ? "Detected" : "None")
                            .foregroundColor(metrics.earlyExtension ? .red : .green)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Divider()
                
                // AI Feedback
                VStack(alignment: .leading, spacing: 12) {
                    Text("Coaching Feedback")
                        .font(.headline)
                    
                    if feedback.isEmpty {
                        Text("Click 'Analyze Swing' to receive AI-powered coaching feedback")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        Text(feedback)
                            .font(.body)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
        }
    }
}

struct MetricRow: View {
    let label: String
    let value: Float?
    let unit: String
    
    var body: some View {
        HStack {
            Text("\(label):")
                .fontWeight(.medium)
            Spacer()
            if let value = value {
                Text(String(format: "%.1f%@", value, unit))
                    .fontWeight(.semibold)
            } else {
                Text("--")
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    CoachingView(
        feedback: "Your spine angle is too upright at address. Try to tilt more forward from your hips while maintaining a straight back. This will help you rotate properly and maintain your posture throughout the swing.",
        metrics: SwingMetrics(
            spineAngle: 35.0,
            hipRotation: 45.0,
            shoulderTilt: 20.0,
            wristPathAngle: 15.0,
            handPlaneAngle: 5.0,
            earlyExtension: false
        )
    )
}
