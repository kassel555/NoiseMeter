import SwiftUI

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    @State private var showingHistory = false
    @State private var showingAlertSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color(white: 0.1)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Title
                    VStack(spacing: 4) {
                        Text("Noise Meter")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Real-time sound level monitor")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    // Gauge
                    GaugeView(decibels: audioManager.normalizedDecibels)
                        .frame(height: 220)

                    // Noise level description
                    Text(audioManager.noiseDescription)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(colorForLevel(audioManager.normalizedDecibels))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(colorForLevel(audioManager.normalizedDecibels).opacity(0.2))
                        )

                    // Alert banner
                    if audioManager.isAlertTriggered && audioManager.alertEnabled {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Noise threshold exceeded!")
                            Spacer()
                            Text("\(audioManager.alertCount)x")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Statistics (only when monitoring)
                    if audioManager.isMonitoring {
                        StatisticsView(audioManager: audioManager)
                            .padding(.horizontal)

                        // History graph
                        HistoryGraphView(
                            readings: audioManager.displayableReadings,
                            threshold: audioManager.alertEnabled ? audioManager.alertThreshold : nil
                        )
                        .frame(height: 120)
                        .padding(.horizontal)
                    }

                    Spacer()

                    // Scale indicator
                    HStack {
                        Text("0")
                        Spacer()
                        Text("60")
                        Spacer()
                        Text("120")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 40)

                    // Start/Stop button
                    Button(action: {
                        if audioManager.isMonitoring {
                            audioManager.stopMonitoring()
                        } else {
                            audioManager.startMonitoring()
                        }
                    }) {
                        HStack {
                            Image(systemName: audioManager.isMonitoring ? "stop.fill" : "mic.fill")
                            Text(audioManager.isMonitoring ? "Stop" : "Start Monitoring")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(audioManager.isMonitoring ? Color.red : Color.blue)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingHistory = true }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAlertSettings = true }) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(audioManager.alertEnabled ? .orange : .gray)
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
                }
            }
            .sheet(isPresented: $showingHistory) {
                SessionHistoryView()
            }
            .sheet(isPresented: $showingAlertSettings) {
                AlertSettingsView(audioManager: audioManager)
            }
        }
        .preferredColorScheme(.dark)
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
    ContentView()
}
