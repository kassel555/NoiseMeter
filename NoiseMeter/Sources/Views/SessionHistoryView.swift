import SwiftUI
import Charts

struct SessionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sessions: [NoiseSession] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if sessions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No Sessions Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        Text("Start monitoring to record noise data")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(sessions) { session in
                            NavigationLink(destination: SessionDetailView(session: session)) {
                                SessionRowView(session: session)
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                        .onDelete(perform: deleteSession)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }

                if !sessions.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                            .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                sessions = DataManager.shared.getSessions()
            }
        }
        .preferredColorScheme(.dark)
    }

    private func deleteSession(at offsets: IndexSet) {
        for index in offsets {
            DataManager.shared.deleteSession(id: sessions[index].id)
        }
        sessions = DataManager.shared.getSessions()
    }
}

struct SessionRowView: View {
    let session: NoiseSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.startTime, style: .date)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text(session.startTime, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            HStack(spacing: 16) {
                StatLabel(title: "Avg", value: String(format: "%.0f dB", session.averageDecibels), color: .blue)
                StatLabel(title: "Max", value: String(format: "%.0f dB", session.maxDecibels), color: .orange)
                StatLabel(title: "Duration", value: session.formattedDuration, color: .purple)

                if session.alertCount > 0 {
                    StatLabel(title: "Alerts", value: "\(session.alertCount)", color: .red)
                }
            }

            // Mini chart
            if !session.readings.isEmpty {
                MiniChartView(readings: session.readings)
                    .frame(height: 40)
            }
        }
        .padding(.vertical, 8)
    }
}

struct StatLabel: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct MiniChartView: View {
    let readings: [NoiseSession.SavedReading]

    var body: some View {
        Chart {
            ForEach(Array(readings.enumerated()), id: \.offset) { index, reading in
                AreaMark(
                    x: .value("Index", index),
                    y: .value("dB", reading.decibels)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue.opacity(0.4), .blue.opacity(0.1)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Index", index),
                    y: .value("dB", reading.decibels)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 1))
            }
        }
        .chartYScale(domain: 0...120)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }
}

struct SessionDetailView: View {
    let session: NoiseSession

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 4) {
                        Text(session.startTime, style: .date)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("\(session.startTime, style: .time) - \(session.endTime ?? Date(), style: .time)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top)

                    // Stats grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        DetailStatBox(title: "Duration", value: session.formattedDuration, icon: "clock", color: .purple)
                        DetailStatBox(title: "Readings", value: "\(session.readings.count)", icon: "waveform", color: .blue)
                        DetailStatBox(title: "Average", value: String(format: "%.1f dB", session.averageDecibels), icon: "equal.circle", color: .cyan)
                        DetailStatBox(title: "Peak", value: String(format: "%.1f dB", session.maxDecibels), icon: "arrow.up.circle", color: .orange)
                        DetailStatBox(title: "Minimum", value: String(format: "%.1f dB", session.minDecibels), icon: "arrow.down.circle", color: .green)
                        DetailStatBox(title: "Alerts", value: "\(session.alertCount)", icon: "bell", color: .red)
                    }
                    .padding(.horizontal)

                    // Full chart
                    if !session.readings.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Noise History")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)

                            DetailChartView(readings: session.readings, threshold: session.alertThreshold)
                                .frame(height: 200)
                                .padding(.horizontal)
                        }
                    }

                    Spacer()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailStatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct DetailChartView: View {
    let readings: [NoiseSession.SavedReading]
    let threshold: Float

    var body: some View {
        Chart {
            ForEach(Array(readings.enumerated()), id: \.offset) { index, reading in
                AreaMark(
                    x: .value("Index", index),
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

                LineMark(
                    x: .value("Index", index),
                    y: .value("dB", reading.decibels)
                )
                .foregroundStyle(colorForLevel(reading.decibels))
                .lineStyle(StrokeStyle(lineWidth: 2))
            }

            RuleMark(y: .value("Threshold", threshold))
                .foregroundStyle(.red.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
        }
        .chartYScale(domain: 0...120)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
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
    SessionHistoryView()
}
