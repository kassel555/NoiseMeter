import SwiftUI

struct StatisticsView: View {
    @ObservedObject var audioManager: AudioManager

    var body: some View {
        HStack(spacing: 12) {
            StatBox(title: "Min", value: String(format: "%.0f", audioManager.minDecibels), unit: "dB", color: .green)
            StatBox(title: "Avg", value: String(format: "%.0f", audioManager.averageDecibels), unit: "dB", color: .blue)
            StatBox(title: "Max", value: String(format: "%.0f", audioManager.maxDecibels), unit: "dB", color: .orange)
            StatBox(title: "Peak", value: String(format: "%.0f", audioManager.peakLevel), unit: "dB", color: .red)
            StatBox(title: "Time", value: audioManager.formattedDuration, unit: "", color: .purple)
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)

            if !unit.isEmpty {
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    StatisticsView(audioManager: AudioManager())
        .padding()
        .background(Color.black)
}
