import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> NoiseEntry {
        NoiseEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (NoiseEntry) -> Void) {
        let entry = NoiseEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NoiseEntry>) -> Void) {
        let entry = NoiseEntry(date: Date())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct NoiseEntry: TimelineEntry {
    let date: Date
}

struct NoiseMeterWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView()
        case .systemMedium:
            MediumWidgetView()
        case .systemLarge:
            LargeWidgetView()
        default:
            SmallWidgetView()
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(gradient)

            VStack(spacing: 12) {
                // Sound bars icon
                HStack(spacing: 4) {
                    ForEach(0..<5) { i in
                        let heights: [CGFloat] = [0.4, 0.7, 1.0, 0.7, 0.4]
                        RoundedRectangle(cornerRadius: 3)
                            .fill(colorForBarIndex(i))
                            .frame(width: 10, height: 50 * heights[i])
                    }
                }

                Text("Noise Meter")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Tap to monitor")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
        }
    }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.1, green: 0.1, blue: 0.18), Color(red: 0.2, green: 0.1, blue: 0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(gradient)

            HStack(spacing: 24) {
                // Left - sound bars
                HStack(spacing: 5) {
                    ForEach(0..<7) { i in
                        let heights: [CGFloat] = [0.3, 0.5, 0.7, 1.0, 0.7, 0.5, 0.3]
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colorForBarIndex(i))
                            .frame(width: 12, height: 70 * heights[i])
                    }
                }

                // Right - text
                VStack(alignment: .leading, spacing: 8) {
                    Text("Noise Meter")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Monitor ambient sound levels in real-time")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)

                    Spacer()

                    HStack {
                        Image(systemName: "mic.fill")
                            .foregroundColor(.blue)
                        Text("Tap to start")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .padding()
        }
    }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.1, green: 0.1, blue: 0.18), Color(red: 0.2, green: 0.1, blue: 0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(gradient)

            VStack(spacing: 20) {
                Text("Noise Meter")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                // Large sound bars
                HStack(spacing: 8) {
                    ForEach(0..<7) { i in
                        let heights: [CGFloat] = [0.3, 0.5, 0.7, 1.0, 0.7, 0.5, 0.3]
                        RoundedRectangle(cornerRadius: 6)
                            .fill(colorForBarIndex(i))
                            .frame(width: 24, height: 120 * heights[i])
                    }
                }

                VStack(spacing: 8) {
                    Text("Real-time Sound Monitor")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))

                    Text("Measure decibel levels, track noise history, and get alerts when it's too loud")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                HStack(spacing: 20) {
                    FeatureItem(icon: "waveform", text: "Live Levels")
                    FeatureItem(icon: "chart.line.uptrend.xyaxis", text: "History")
                    FeatureItem(icon: "bell.fill", text: "Alerts")
                }

                Spacer()

                HStack {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.blue)
                    Text("Tap to start monitoring")
                        .foregroundColor(.white.opacity(0.8))
                }
                .font(.subheadline)
            }
            .padding()
        }
    }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.1, green: 0.1, blue: 0.18), Color(red: 0.2, green: 0.1, blue: 0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct FeatureItem: View {
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Helper Functions

func colorForBarIndex(_ index: Int) -> Color {
    let colors: [Color] = [
        Color(red: 1.0, green: 0.85, blue: 0.24),  // yellow
        Color(red: 1.0, green: 0.62, blue: 0.11),  // orange
        Color(red: 1.0, green: 0.42, blue: 0.42),  // light red
        Color(red: 1.0, green: 0.23, blue: 0.19),  // red
        Color(red: 1.0, green: 0.42, blue: 0.42),  // light red
        Color(red: 1.0, green: 0.62, blue: 0.11),  // orange
        Color(red: 1.0, green: 0.85, blue: 0.24),  // yellow
    ]
    return colors[min(index, colors.count - 1)]
}

// MARK: - Widget Configuration

@main
struct NoiseMeterWidget: Widget {
    let kind: String = "NoiseMeterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            NoiseMeterWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Noise Meter")
        .description("Quick access to monitor ambient noise levels.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    NoiseMeterWidget()
} timeline: {
    NoiseEntry(date: .now)
}

#Preview(as: .systemMedium) {
    NoiseMeterWidget()
} timeline: {
    NoiseEntry(date: .now)
}

#Preview(as: .systemLarge) {
    NoiseMeterWidget()
} timeline: {
    NoiseEntry(date: .now)
}
