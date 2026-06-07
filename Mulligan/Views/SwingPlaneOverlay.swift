import SwiftUI

struct SwingPlaneOverlay: View {
    @Binding var points: [CGPoint]
    @Binding var isDrawing: Bool
    
    var body: some View {
        ZStack {
            // Drawing area
            GeometryReader { geometry in
                Path { path in
                    if points.count >= 2 {
                        path.move(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                }
                .stroke(Color.red, lineWidth: 2)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if isDrawing {
                                points.append(value.location)
                            }
                        }
                )
            }
            
            // Drawing mode toggle
            VStack {
                Spacer()
                HStack {
                    Toggle("Draw Swing Plane", isOn: $isDrawing)
                        .padding()
                    Spacer()
                    Button("Clear") {
                        points = []
                    }
                    .padding()
                }
            }
        }
    }
}
