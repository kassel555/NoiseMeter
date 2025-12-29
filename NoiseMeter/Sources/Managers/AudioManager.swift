import AVFoundation
import Combine
import UIKit

struct NoiseReading: Identifiable {
    let id = UUID()
    let timestamp: Date
    let decibels: Float
}

class AudioManager: ObservableObject {
    @Published var decibelLevel: Float = -160
    @Published var isMonitoring: Bool = false
    @Published var permissionGranted: Bool = false
    @Published var readings: [NoiseReading] = []
    @Published var peakLevel: Float = 0

    // Alert settings
    @Published var alertEnabled: Bool = true
    @Published var alertThreshold: Float = 80
    @Published var isAlertTriggered: Bool = false
    @Published var alertCount: Int = 0

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var historyTimer: Timer?
    private var sessionStartTime: Date?

    // Persistence
    private let dataManager = DataManager.shared
    private var currentSessionId: UUID?

    // Alert cooldown to prevent spam
    private var lastAlertTime: Date?
    private let alertCooldown: TimeInterval = 2.0

    // Haptic feedback generators
    private let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    // Keep readings for the session (no limit for saved sessions)
    private let displayReadings = 120 // Show last 60 seconds on screen
    private let saveInterval: TimeInterval = 0.5

    init() {
        checkPermission()
        impactGenerator.prepare()
        notificationGenerator.prepare()
    }

    func checkPermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            permissionGranted = true
        case .denied:
            permissionGranted = false
        case .undetermined:
            requestPermission()
        @unknown default:
            permissionGranted = false
        }
    }

    func requestPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.permissionGranted = granted
            }
        }
    }

    func startMonitoring() {
        guard permissionGranted else {
            requestPermission()
            return
        }

        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .defaultToSpeaker)
            try audioSession.setActive(true)

            let url = getDocumentsDirectory().appendingPathComponent("noise_meter.caf")

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatAppleIMA4),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()

            isMonitoring = true
            sessionStartTime = Date()
            readings = []
            peakLevel = 0
            alertCount = 0
            lastAlertTime = nil

            // Create new session for persistence
            let session = dataManager.createSession(alertThreshold: alertThreshold)
            currentSessionId = session.id

            // Fast timer for real-time display
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                self?.updateMeters()
            }

            // Timer for history recording and saving (every 0.5 seconds)
            historyTimer = Timer.scheduledTimer(withTimeInterval: saveInterval, repeats: true) { [weak self] _ in
                self?.recordAndSaveReading()
            }

        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        historyTimer?.invalidate()
        historyTimer = nil
        audioRecorder?.stop()
        audioRecorder = nil
        isMonitoring = false
        decibelLevel = -160
        isAlertTriggered = false

        // End and save the session
        if let sessionId = currentSessionId {
            dataManager.endSession(id: sessionId, readings: readings, alertCount: alertCount)
            currentSessionId = nil
        }
    }

    func resetSession() {
        readings = []
        peakLevel = 0
        alertCount = 0
        sessionStartTime = Date()
        lastAlertTime = nil
    }

    private func updateMeters() {
        guard let recorder = audioRecorder else { return }

        recorder.updateMeters()
        let averagePower = recorder.averagePower(forChannel: 0)

        DispatchQueue.main.async {
            self.decibelLevel = averagePower

            // Track peak
            let normalized = self.normalizedDecibels
            if normalized > self.peakLevel {
                self.peakLevel = normalized
            }

            // Check alert threshold
            self.checkAlert(level: normalized)
        }
    }

    private func checkAlert(level: Float) {
        let wasTriggered = isAlertTriggered
        isAlertTriggered = level >= alertThreshold

        // Trigger alert with cooldown
        if alertEnabled && isAlertTriggered && !wasTriggered {
            let now = Date()
            if let lastAlert = lastAlertTime {
                if now.timeIntervalSince(lastAlert) >= alertCooldown {
                    triggerAlert()
                    lastAlertTime = now
                }
            } else {
                triggerAlert()
                lastAlertTime = now
            }
        }
    }

    private func triggerAlert() {
        alertCount += 1

        // Haptic feedback
        impactGenerator.impactOccurred()

        // Double haptic for emphasis
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.notificationGenerator.notificationOccurred(.warning)
        }
    }

    private func recordAndSaveReading() {
        let reading = NoiseReading(timestamp: Date(), decibels: normalizedDecibels)

        DispatchQueue.main.async {
            self.readings.append(reading)

            // Save to persistent storage every 0.5 seconds
            if let sessionId = self.currentSessionId {
                self.dataManager.updateSession(
                    id: sessionId,
                    readings: self.readings,
                    alertCount: self.alertCount
                )
            }

        }
    }

    // Readings for display (last 60 seconds)
    var displayableReadings: [NoiseReading] {
        if readings.count <= displayReadings {
            return readings
        }
        return Array(readings.suffix(displayReadings))
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // Convert the raw dB value to a normalized 0-120 scale for display
    var normalizedDecibels: Float {
        let minDb: Float = -80
        let maxDb: Float = 0

        let clampedLevel = max(minDb, min(maxDb, decibelLevel))
        let normalized = (clampedLevel - minDb) / (maxDb - minDb)

        return normalized * 120
    }

    // Get a description of the noise level
    var noiseDescription: String {
        let db = normalizedDecibels
        switch db {
        case 0..<30:
            return "Quiet"
        case 30..<50:
            return "Moderate"
        case 50..<70:
            return "Loud"
        case 70..<90:
            return "Very Loud"
        case 90..<120:
            return "Dangerous"
        default:
            return "Extreme"
        }
    }

    // MARK: - Statistics

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

    var sessionDuration: TimeInterval {
        guard let start = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(start)
    }

    var formattedDuration: String {
        let duration = Int(sessionDuration)
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let seconds = duration % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
