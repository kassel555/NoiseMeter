import SwiftUI

struct AlertSettingsView: View {
    @ObservedObject var audioManager: AudioManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Enable Alerts", isOn: $audioManager.alertEnabled)

                    if audioManager.alertEnabled {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Threshold")
                                Spacer()
                                Text("\(Int(audioManager.alertThreshold)) dB")
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }

                            Slider(
                                value: $audioManager.alertThreshold,
                                in: 50...110,
                                step: 5
                            )
                            .tint(colorForThreshold(audioManager.alertThreshold))

                            HStack {
                                Text("50 dB")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("110 dB")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Alert Settings")
                } footer: {
                    Text("You'll receive haptic feedback when noise exceeds the threshold.")
                }

                Section("Reference Levels") {
                    ReferenceLevelRow(name: "Whisper", level: "30 dB", icon: "speaker.wave.1")
                    ReferenceLevelRow(name: "Normal conversation", level: "60 dB", icon: "speaker.wave.2")
                    ReferenceLevelRow(name: "Vacuum cleaner", level: "75 dB", icon: "speaker.wave.3")
                    ReferenceLevelRow(name: "Heavy traffic", level: "85 dB", icon: "car.fill")
                    ReferenceLevelRow(name: "Concert", level: "100 dB", icon: "music.note")
                    ReferenceLevelRow(name: "Jet engine", level: "120 dB", icon: "airplane")
                }
            }
            .navigationTitle("Alert Settings")
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

    private func colorForThreshold(_ threshold: Float) -> Color {
        switch threshold {
        case 0..<60:
            return .green
        case 60..<80:
            return .yellow
        case 80..<100:
            return .orange
        default:
            return .red
        }
    }
}

struct ReferenceLevelRow: View {
    let name: String
    let level: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)

            Text(name)

            Spacer()

            Text(level)
                .foregroundColor(.secondary)
                .monospacedDigit()
        }
    }
}

struct AlertBanner: View {
    let threshold: Float
    let alertCount: Int
    let isTriggered: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isTriggered ? "speaker.wave.3.fill" : "bell.fill")
                .font(.title2)
                .foregroundColor(.white)
                .symbolEffect(.bounce, value: isTriggered)

            VStack(alignment: .leading, spacing: 2) {
                Text(isTriggered ? "TOO LOUD!" : "Alert Active")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Threshold: \(Int(threshold)) dB")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            if alertCount > 0 {
                Text("\(alertCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(isTriggered ? Color.red : Color.orange)
        .cornerRadius(16)
        .animation(.easeInOut(duration: 0.2), value: isTriggered)
    }
}

#Preview {
    AlertSettingsView(audioManager: AudioManager())
}
