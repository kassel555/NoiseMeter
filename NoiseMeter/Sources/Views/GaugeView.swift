import SwiftUI

struct GaugeView: View {
    let decibels: Float

    private let minValue: Float = 0
    private let maxValue: Float = 120

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: size * 0.7)
            let radius = size * 0.45

            ZStack {
                // Background arc
                ArcShape(startAngle: .degrees(180), endAngle: .degrees(360))
                    .stroke(
                        Color.gray.opacity(0.3),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)

                // Colored arc segments
                ForEach(0..<5, id: \.self) { index in
                    let startDegree = 180.0 + Double(index) * 36.0
                    let endDegree = startDegree + 36.0

                    ArcShape(
                        startAngle: .degrees(startDegree),
                        endAngle: .degrees(endDegree)
                    )
                    .stroke(
                        colorForSegment(index),
                        style: StrokeStyle(lineWidth: 20, lineCap: .butt)
                    )
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)
                    .opacity(segmentOpacity(for: index))
                }

                // Tick marks
                ForEach(0..<13, id: \.self) { index in
                    let angle = Angle.degrees(180.0 + Double(index) * 15.0)
                    let innerRadius = radius - 30
                    let outerRadius = radius - 15
                    let isMajor = index % 3 == 0

                    Path { path in
                        let startX = center.x + CGFloat(cos(angle.radians)) * (isMajor ? innerRadius - 5 : innerRadius)
                        let startY = center.y + CGFloat(sin(angle.radians)) * (isMajor ? innerRadius - 5 : innerRadius)
                        let endX = center.x + CGFloat(cos(angle.radians)) * outerRadius
                        let endY = center.y + CGFloat(sin(angle.radians)) * outerRadius

                        path.move(to: CGPoint(x: startX, y: startY))
                        path.addLine(to: CGPoint(x: endX, y: endY))
                    }
                    .stroke(Color.white.opacity(0.5), lineWidth: isMajor ? 2 : 1)
                }

                // Needle
                NeedleShape()
                    .fill(Color.white)
                    .frame(width: 8, height: radius - 20)
                    .offset(y: -(radius - 20) / 2)
                    .rotationEffect(needleAngle, anchor: .bottom)
                    .position(center)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)

                // Center circle
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [Color.white, Color.gray]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 15
                        )
                    )
                    .frame(width: 24, height: 24)
                    .position(center)

                // Value display
                VStack(spacing: 2) {
                    Text("\(Int(decibels))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("dB")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .position(x: center.x, y: center.y + 30)
            }
        }
    }

    private var needleAngle: Angle {
        let normalized = (decibels - minValue) / (maxValue - minValue)
        let clampedNormalized = max(0, min(1, normalized))
        let degrees = -90 + Double(clampedNormalized) * 180
        return .degrees(degrees)
    }

    private func colorForSegment(_ index: Int) -> Color {
        switch index {
        case 0: return .green
        case 1: return .yellow
        case 2: return .orange
        case 3: return .red
        case 4: return .purple
        default: return .gray
        }
    }

    private func segmentOpacity(for index: Int) -> Double {
        let segmentValue = Float(index + 1) * 24
        return decibels >= Float(index) * 24 ? 1.0 : 0.3
    }
}

struct ArcShape: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}

struct NeedleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: 0))
        path.addLine(to: CGPoint(x: rect.midX - 4, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX + 4, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    GaugeView(decibels: 65)
        .frame(height: 250)
        .background(Color.black)
}
