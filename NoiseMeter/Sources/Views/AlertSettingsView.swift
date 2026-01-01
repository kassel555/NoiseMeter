import SwiftUI

struct AlertSettingsView: View {
    @ObservedObject var audioManager: AudioManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Enable toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Noise Alerts")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Text("Get haptic feedback when noise exceeds threshold")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Toggle("", isOn: $audioManager.alertEnabled)
                                .labelsHidden()
                                .tint(.orange)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)

                        // Threshold slider
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Alert Threshold")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Spacer()

                                Text("\(Int(audioManager.alertThreshold)) dB")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(colorForLevel(audioManager.alertThreshold))
                            }

                            Slider(
                                value: $audioManager.alertThreshold,
                                in: 50...110,
                                step: 5
                            )
                            .tint(colorForLevel(audioManager.alertThreshold))

                            HStack {
                                Text("50 dB")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("110 dB")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .opacity(audioManager.alertEnabled ? 1 : 0.5)
                        .disabled(!audioManager.alertEnabled)

                        // Reference levels
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reference Levels")
                                .font(.headline)
                                .foregroundColor(.white)

                            VStack(spacing: 8) {
                                ReferenceLevelRow(name: "Library", level: 30, color: .green)
                                ReferenceLevelRow(name: "Normal conversation", level: 60, color: .yellow)
                                ReferenceLevelRow(name: "Busy traffic", level: 70, color: .orange)
                                ReferenceLevelRow(name: "Lawn mower", level: 85, color: .red)
                                ReferenceLevelRow(name: "Rock concert", level: 100, color: .purple)
                                ReferenceLevelRow(name: "Jet engine", level: 120, color: .purple)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Alert Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
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

struct ReferenceLevelRow: View {
    let name: String
    let level: Int
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(name)
                .foregroundColor(.white)

            Spacer()

            Text("\(level) dB")
                .foregroundColor(.gray)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    AlertSettingsView(audioManager: AudioManager())
}
