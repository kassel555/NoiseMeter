import SwiftUI

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    @State private var showingSettings = false
    @State private var showingHistory = false

    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
                .ignoresSafeArea()

            if audioManager.permissionGranted {
                mainContent
            } else {
                permissionDeniedView
            }
        }
        .sheet(isPresented: $showingSettings) {
            AlertSettingsView(audioManager: audioManager)
        }
        .sheet(isPresented: $showingHistory) {
            SessionHistoryView()
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                audioManager.isAlertTriggered ? Color.red.opacity(0.1) : Color(.systemBackground),
                Color(.systemGray6)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .animation(.easeInOut(duration: 0.3), value: audioManager.isAlertTriggered)
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with title and buttons
                headerView

                // Alert banner (when enabled and monitoring)
                if audioManager.alertEnabled && audioManager.isMonitoring {
                    AlertBanner(
                        threshold: audioManager.alertThreshold,
                        alertCount: audioManager.alertCount,
                        isTriggered: audioManager.isAlertTriggered
                    )
                    .padding(.horizontal)
                }

                // Gauge display
                GaugeView(
                    value: audioManager.normalizedDecibels,
                    label: audioManager.noiseDescription
                )

                // Statistics (only show when monitoring or has data)
                if audioManager.isMonitoring || !audioManager.readings.isEmpty {
                    StatisticsView(
                        min: audioManager.minDecibels,
                        max: audioManager.maxDecibels,
                        average: audioManager.averageDecibels,
                        peak: audioManager.peakLevel,
                        duration: audioManager.formattedDuration
                    )
                    .padding(.horizontal)

                    // History Graph (shows last 60 seconds)
                    HistoryGraphView(readings: audioManager.displayableReadings)
                        .padding(.horizontal)
                }

                // Start/Stop button
                Button(action: {
                    if audioManager.isMonitoring {
                        audioManager.stopMonitoring()
                    } else {
                        audioManager.startMonitoring()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: audioManager.isMonitoring ? "stop.fill" : "mic.fill")
                            .font(.title2)

                        Text(audioManager.isMonitoring ? "Stop" : "Start Monitoring")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(audioManager.isMonitoring ? Color.red : Color.blue)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 40)

                // Reset button (only show when has data and not monitoring)
                if !audioManager.isMonitoring && !audioManager.readings.isEmpty {
                    Button(action: {
                        audioManager.resetSession()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                }

                Spacer(minLength: 40)
            }
        }
    }

    private var headerView: some View {
        HStack {
            // History button
            Button(action: {
                showingHistory = true
            }) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(width: 44, height: 44)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            .padding(.leading)

            Spacer()

            VStack(spacing: 4) {
                Text("Noise Meter")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Real-time sound level monitor")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Settings button
            Button(action: {
                showingSettings = true
            }) {
                Image(systemName: audioManager.alertEnabled ? "bell.fill" : "bell.slash")
                    .font(.title2)
                    .foregroundColor(audioManager.alertEnabled ? .orange : .secondary)
                    .frame(width: 44, height: 44)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            .padding(.trailing)
        }
        .padding(.top, 20)
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "mic.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Microphone Access Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Please enable microphone access in Settings to measure noise levels.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
