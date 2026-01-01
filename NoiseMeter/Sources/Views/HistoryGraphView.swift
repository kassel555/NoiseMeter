import SwiftUI
import Charts

struct HistoryGraphView: View {
    let readings: [NoiseReading]
    let threshold: Float?

    var body: some View {
        Chart {
            // Area fill
            ForEach(readings) { reading in
                AreaMark(
                    x: .value("Time", reading.timestamp),
                    y: .value("dB", reading.decibels)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            colorForLevel(reading.decibels).opacity(0.3),
                            colorForLevel(reading.decibels).opacity(0.1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }

            // Line
            ForEach(readings) { reading in
                LineMark(
                    x: .value("Time", reading.timestamp),
                    y: .value("dB", reading.decibels)
                )
                .foregroundStyle(colorForLevel(reading.decibels))
                .lineStyle(StrokeStyle(lineWidth: 2))
            }

            // Threshold line
            if let threshold = threshold {
                RuleMark(y: .value("Threshold", threshold))
                    .foregroundStyle(.red.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
            }
        }
        .chartYScale(domain: 0...120)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.3))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 30, 60, 90, 120]) { value in
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.3))
                AxisValueLabel()
                    .foregroundStyle(Color.gray)
            }
        }
    }

    private func colorForLevel(_ db: Float) -> Color {
        switch db {
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
}

#Preview {
    let sampleReadings = (0..<60).map { i in
        NoiseReading(
            timestamp: Date().addingTimeInterval(Double(i) * -0.5),
            decibels: Float.random(in: 30...80)
        )
    }

    return HistoryGraphView(readings: sampleReadings, threshold: 70)
        .frame(height: 150)
        .padding()
        .background(Color.black)
}
