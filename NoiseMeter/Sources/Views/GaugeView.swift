import SwiftUI

struct GaugeView: View {
    let value: Float // 0-120 dB range
    let label: String

    private let minValue: Float = 0
    private let maxValue: Float = 120

    private var normalizedValue: Double {
        Double((value - minValue) / (maxValue - minValue))
    }

    private var gaugeColor: Color {
        switch value {
        case 0..<30:
            return .green
        case 30..<50:
            return .yellow
        case 50..<70:
            return .orange
        case 70..<90:
            return .red
        default:
            return .purple
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Background arc
                Circle()
                    .trim(from: 0.25, to: 0.75)
                    .stroke(
                        Color.gray.opacity(0.2),
                        style: StrokeStyle(lineWidth: 30, lineCap: .round)
                    )
                    .rotationEffect(.degrees(90))

                // Colored arc showing level
                Circle()
                    .trim(from: 0.25, to: 0.25 + (0.5 * normalizedValue))
                    .stroke(
                        gaugeColor,
                        style: StrokeStyle(lineWidth: 30, lineCap: .round)
                    )
                    .rotationEffect(.degrees(90))
                    .animation(.easeOut(duration: 0.1), value: value)

                // Tick marks
                ForEach(0..<13) { index in
                    TickMark(index: index)
                }

                // Center display
                VStack(spacing: 8) {
                    Text("\(Int(value))")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                        .animation(.easeOut(duration: 0.1), value: Int(value))

                    Text("dB")
                        .font(.title2)
                        .foregroundColor(.secondary)

                    Text(label)
                        .font(.headline)
                        .foregroundColor(gaugeColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(gaugeColor.opacity(0.15))
                        .cornerRadius(20)
                }
            }
            .frame(width: 300, height: 300)

            // Scale labels
            HStack {
                Text("0")
                Spacer()
                Text("60")
                Spacer()
                Text("120")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(width: 260)
        }
    }
}

struct TickMark: View {
    let index: Int

    var body: some View {
        let angle = Double(index) * 15 - 90 // 15 degrees per tick, starting from left
        let isMajor = index % 3 == 0

        Rectangle()
            .fill(Color.gray.opacity(0.5))
            .frame(width: isMajor ? 3 : 1.5, height: isMajor ? 15 : 10)
            .offset(y: -120)
            .rotationEffect(.degrees(angle))
    }
}

struct LevelIndicator: View {
    let level: Float
    let maxLevel: Float = 120

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))

                // Fill
                RoundedRectangle(cornerRadius: 10)
                    .fill(levelGradient)
                    .frame(height: geometry.size.height * CGFloat(level / maxLevel))
            }
        }
        .frame(width: 40)
    }

    private var levelGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.green, .yellow, .orange, .red]),
            startPoint: .bottom,
            endPoint: .top
        )
    }
}

#Preview {
    GaugeView(value: 65, label: "Loud")
        .padding()
}
