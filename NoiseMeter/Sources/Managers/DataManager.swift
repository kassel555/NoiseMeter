import Foundation

struct NoiseSession: Identifiable, Codable {
    let id: UUID
    let startDate: Date
    var endDate: Date?
    var readings: [SavedReading]
    var alertCount: Int
    var alertThreshold: Float

    var duration: TimeInterval {
        let end = endDate ?? Date()
        return end.timeIntervalSince(startDate)
    }

    var formattedDuration: String {
        let duration = Int(self.duration)
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let seconds = duration % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startDate)
    }

    var averageDecibels: Float {
        guard !readings.isEmpty else { return 0 }
        let sum = readings.reduce(0) { $0 + $1.decibels }
        return sum / Float(readings.count)
    }

    var minDecibels: Float {
        readings.map { $0.decibels }.min() ?? 0
    }

    var maxDecibels: Float {
        readings.map { $0.decibels }.max() ?? 0
    }

    var peakDecibels: Float {
        readings.map { $0.decibels }.max() ?? 0
    }
}

struct SavedReading: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let decibels: Float

    init(from reading: NoiseReading) {
        self.id = reading.id
        self.timestamp = reading.timestamp
        self.decibels = reading.decibels
    }

    init(id: UUID = UUID(), timestamp: Date, decibels: Float) {
        self.id = id
        self.timestamp = timestamp
        self.decibels = decibels
    }
}

class DataManager: ObservableObject {
    static let shared = DataManager()

    @Published var sessions: [NoiseSession] = []

    private let sessionsKey = "noise_sessions"
    private let fileManager = FileManager.default

    private var sessionsFileURL: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("noise_sessions.json")
    }

    init() {
        loadSessions()
    }

    // MARK: - Session Management

    func createSession(alertThreshold: Float) -> NoiseSession {
        let session = NoiseSession(
            id: UUID(),
            startDate: Date(),
            endDate: nil,
            readings: [],
            alertCount: 0,
            alertThreshold: alertThreshold
        )
        sessions.insert(session, at: 0)
        saveSessions()
        return session
    }

    func updateSession(id: UUID, readings: [NoiseReading], alertCount: Int) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }

        sessions[index].readings = readings.map { SavedReading(from: $0) }
        sessions[index].alertCount = alertCount
        saveSessions()
    }

    func endSession(id: UUID, readings: [NoiseReading], alertCount: Int) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }

        sessions[index].endDate = Date()
        sessions[index].readings = readings.map { SavedReading(from: $0) }
        sessions[index].alertCount = alertCount
        saveSessions()
    }

    func deleteSession(id: UUID) {
        sessions.removeAll { $0.id == id }
        saveSessions()
    }

    func deleteAllSessions() {
        sessions.removeAll()
        saveSessions()
    }

    // MARK: - Persistence

    private func saveSessions() {
        do {
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: sessionsFileURL)
        } catch {
            print("Failed to save sessions: \(error)")
        }
    }

    private func loadSessions() {
        guard fileManager.fileExists(atPath: sessionsFileURL.path) else { return }

        do {
            let data = try Data(contentsOf: sessionsFileURL)
            sessions = try JSONDecoder().decode([NoiseSession].self, from: data)
        } catch {
            print("Failed to load sessions: \(error)")
        }
    }
}
