import Foundation

struct NoiseSession: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    var readings: [SavedReading]
    var alertThreshold: Float
    var alertCount: Int

    struct SavedReading: Codable {
        let timestamp: Date
        let decibels: Float
    }

    var duration: TimeInterval {
        guard let end = endTime else { return 0 }
        return end.timeIntervalSince(startTime)
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

    var formattedDuration: String {
        let dur = Int(duration)
        let hours = dur / 3600
        let minutes = (dur % 3600) / 60
        let seconds = dur % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

class DataManager {
    static let shared = DataManager()

    private let sessionsKey = "noise_sessions"
    private var sessions: [NoiseSession] = []

    private init() {
        loadSessions()
    }

    func createSession(alertThreshold: Float) -> NoiseSession {
        let session = NoiseSession(
            id: UUID(),
            startTime: Date(),
            endTime: nil,
            readings: [],
            alertThreshold: alertThreshold,
            alertCount: 0
        )
        sessions.insert(session, at: 0)
        saveSessions()
        return session
    }

    func updateSession(id: UUID, readings: [NoiseReading], alertCount: Int) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].readings = readings.map {
            NoiseSession.SavedReading(timestamp: $0.timestamp, decibels: $0.decibels)
        }
        sessions[index].alertCount = alertCount
        saveSessions()
    }

    func endSession(id: UUID, readings: [NoiseReading], alertCount: Int) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].endTime = Date()
        sessions[index].readings = readings.map {
            NoiseSession.SavedReading(timestamp: $0.timestamp, decibels: $0.decibels)
        }
        sessions[index].alertCount = alertCount
        saveSessions()
    }

    func getSessions() -> [NoiseSession] {
        return sessions.filter { $0.endTime != nil }
    }

    func deleteSession(id: UUID) {
        sessions.removeAll { $0.id == id }
        saveSessions()
    }

    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: sessionsKey)
        }
    }

    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([NoiseSession].self, from: data) {
            sessions = decoded
        }
    }
}
