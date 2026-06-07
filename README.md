# Mulligan - Golf Swing Analysis App

A macOS application that uses computer vision and AI to analyze golf swings in real-time.

## Features

- **Continuity Camera Support**: Automatically discovers and uses nearby iPhones as webcams via Apple's Continuity Camera
- **Real-time Pose Detection**: Uses Apple's Vision Framework with VNDetectHumanBodyPoseRequest running on Apple Silicon Neural Engine
- **Custom Swing Plane Drawing**: Draw reference lines directly on the video feed to analyze swing path
- **SIMD-Based Geometry Engine**: High-performance angle calculations for spine, hips, and wrist path
- **AI-Powered Coaching**: Get personalized feedback using OpenAI's GPT-4o-mini API
- **SwiftUI Interface**: Modern, native macOS UI with smooth performance

## Requirements

- macOS 14.0+
- Xcode 15.0+
- Swift 6.0
- Mac with Apple Silicon (M1/M2/M3/M4) for optimal Vision Framework performance
- OpenAI API key (for AI coaching features)

## Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd mulligan
   ```

2. **Open in Xcode**
   ```bash
   open Mulligan.xcodeproj
   ```

3. **Configure OpenAI API Key**
   
   Set your OpenAI API key as an environment variable:
   ```bash
   export OPENAI_API_KEY="your-api-key-here"
   ```
   
   Or modify the `apiKey` in `AICoach.swift` directly.

4. **Build and Run**
   - Select "My Mac" as the destination
   - Press Cmd+R to build and run

## Usage

1. **Select Camera**: Choose from available cameras including iPhones via Continuity Camera
2. **Draw Swing Plane**: Click on the video to draw reference lines for down-the-line analysis
3. **Record**: Click "Record" to start pose detection
4. **Analyze**: Click "Analyze Swing" to receive AI-powered coaching feedback
5. **View Metrics**: Real-time metrics displayed in the right panel

## Architecture

### Core Components

- **VideoCaptureManager**: AVFoundation-based video capture with Continuity Camera support
- **PoseDetector**: Vision Framework integration for human body pose detection
- **GeometryEngine**: SIMD-based trigonometric calculations for swing metrics
- **SwingAnalyzer**: Processes pose data to calculate swing metrics
- **AICoach**: Integrates with OpenAI API for coaching feedback

### SwiftUI Views

- **VideoPreviewView**: Real-time video feed with pose overlay
- **SwingPlaneOverlay**: Interactive drawing for reference lines
- **CoachingView**: Displays metrics and AI feedback

## Metrics Calculated

- **Spine Angle**: Angle of spine relative to vertical
- **Hip Rotation**: Degree of hip turn during swing
- **Shoulder Tilt**: Shoulder angle at address and through swing
- **Wrist Path Angle**: Wrist movement relative to swing plane
- **Hand Plane Angle**: Hand position relative to reference plane
- **Early Extension**: Detection of premature hip movement toward target

## Privacy

- All pose detection runs locally on-device using Apple's Vision Framework
- Video processing never leaves your Mac
- Only calculated metrics are sent to OpenAI for coaching feedback
- No video or image data is transmitted to external services

## License

MIT License

## Future Enhancements

- [ ] Local CoreML model for offline coaching
- [ ] Swing phase detection (backswing, downswing, follow-through)
- [ ] Historical swing data tracking
- [ ] Comparison with professional swings
- [ ] Export analysis reports
