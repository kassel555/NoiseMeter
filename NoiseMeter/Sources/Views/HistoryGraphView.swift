import SwiftUI
import Charts

struct HistoryGraphView: View {
    let readings: [NoiseReading]

    private var displayReadings: [NoiseReading] {
        // Show readings relative to current time
        readings
    }

    private func colorForDecibels(_ db: Float) -> Color {
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("History")
                .font(.headline)
                .foregroundColor(.secondary)

            if readings.isEmpty {
                emptyState
            } else {
                chartView
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title)
                .foregroundColor(.secondary)
            Text("Start monitoring to see history")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }

    private var chartView: some View {
        Chart(readings) { reading in
            LineMark(
                x: .value("Time", reading.timestamp),
                y: .value("dB", reading.decibels)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.green, .yellow, .orange, .red],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .lineStyle(StrokeStyle(lineWidth: 2))

            AreaMark(
                x: .value("Time", reading.timestamp),
                y: .value("dB", reading.decibels)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.blue.opacity(0.3), .blue.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartYScale(domain: 0...120)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 30, 60, 90, 120]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let db = value.as(Int.self) {
                        Text("\(db)")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.minute().second())
            }
        }
        .frame(height: 150)
    }
}

struct StatisticsView: View {
    let min: Float
    let max: Float
    let average: Float
    let peak: Float
    let duration: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                StatBox(title: "Min", value: min, color: .green)
                StatBox(title: "Avg", value: average, color: .blue)
                StatBox(title: "Max", value: max, color: .orange)
                StatBox(title: "Peak", value: peak, color: .red)
            }

            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                Text("Duration: \(duration)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct StatBox: View {
    let title: String
    let value: Float
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\(Int(value))")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text("dB")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    VStack {
        HistoryGraphView(readings: [])
        StatisticsView(min: 25, max: 85, average: 52, peak: 92, duration: "01:30")
    }
    .padding()
}
