import SwiftUI
import Charts

struct SessionHistoryView: View {
    @ObservedObject var dataManager = DataManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSession: NoiseSession?

    var body: some View {
        NavigationView {
            Group {
                if dataManager.sessions.isEmpty {
                    emptyState
                } else {
                    sessionList
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if !dataManager.sessions.isEmpty {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear All", role: .destructive) {
                            dataManager.deleteAllSessions()
                        }
                    }
                }
            }
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text("No Sessions Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Start monitoring to record your first session.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var sessionList: some View {
        List {
            ForEach(dataManager.sessions) { session in
                SessionRow(session: session)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSession = session
                    }
            }
            .onDelete(perform: deleteSession)
        }
        .listStyle(.insetGrouped)
    }

    private func deleteSession(at offsets: IndexSet) {
        for index in offsets {
            dataManager.deleteSession(id: dataManager.sessions[index].id)
        }
    }
}

struct SessionRow: View {
    let session: NoiseSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.formattedDate)
                    .font(.headline)

                Spacer()

                Text(session.formattedDuration)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                StatPill(label: "Avg", value: "\(Int(session.averageDecibels))", unit: "dB", color: .blue)
                StatPill(label: "Peak", value: "\(Int(session.peakDecibels))", unit: "dB", color: .red)

                if session.alertCount > 0 {
                    StatPill(label: "Alerts", value: "\(session.alertCount)", unit: "", color: .orange)
                }

                Spacer()
            }

            // Mini chart
            if !session.readings.isEmpty {
                MiniChart(readings: session.readings)
                    .frame(height: 40)
            }
        }
        .padding(.vertical, 8)
    }
}

struct StatPill: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value + unit)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct MiniChart: View {
    let readings: [SavedReading]

    var body: some View {
        Chart(readings) { reading in
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

            LineMark(
                x: .value("Time", reading.timestamp),
                y: .value("dB", reading.decibels)
            )
            .foregroundStyle(.blue)
            .lineStyle(StrokeStyle(lineWidth: 1))
        }
        .chartYScale(domain: 0...120)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }
}

struct SessionDetailView: View {
    let session: NoiseSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header info
                    VStack(spacing: 8) {
                        Text(session.formattedDate)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Duration: \(session.formattedDuration)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // Statistics
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        DetailStatCard(title: "Average", value: session.averageDecibels, color: .blue)
                        DetailStatCard(title: "Peak", value: session.peakDecibels, color: .red)
                        DetailStatCard(title: "Minimum", value: session.minDecibels, color: .green)
                        DetailStatCard(title: "Maximum", value: session.maxDecibels, color: .orange)
                    }
                    .padding(.horizontal)

                    // Alert info
                    if session.alertCount > 0 {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                            Text("\(session.alertCount) alerts triggered")
                                .foregroundColor(.secondary)
                            Text("(threshold: \(Int(session.alertThreshold)) dB)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Full chart
                    if !session.readings.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Noise Level Over Time")
                                .font(.headline)
                                .padding(.horizontal)

                            DetailChart(readings: session.readings, threshold: session.alertThreshold)
                                .frame(height: 200)
                                .padding(.horizontal)
                        }
                    }

                    // Reading count
                    Text("\(session.readings.count) readings recorded")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                }
            }
            .navigationTitle("Session Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DetailStatCard: View {
    let title: String
    let value: Float
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\(Int(value))")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text("dB")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct DetailChart: View {
    let readings: [SavedReading]
    let threshold: Float

    var body: some View {
        Chart {
            ForEach(readings) { reading in
                LineMark(
                    x: .value("Time", reading.timestamp),
                    y: .value("dB", reading.decibels)
                )
                .foregroundStyle(.blue)
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

            // Threshold line
            RuleMark(y: .value("Threshold", threshold))
                .foregroundStyle(.red.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .annotation(position: .top, alignment: .trailing) {
                    Text("Threshold")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
        }
        .chartYScale(domain: 0...120)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 30, 60, 90, 120])
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour().minute())
            }
        }
    }
}

#Preview {
    SessionHistoryView()
}
