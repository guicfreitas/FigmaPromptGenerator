import AVFoundation
import Combine
import Foundation

@MainActor
final class SpeechTranscriptionService: NSObject, ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var isTranscribing = false
    @Published private(set) var transcript = ""
    @Published private(set) var errorMessage: String?

    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?

    func start() async {
        transcript = ""
        errorMessage = nil
        guard await microphoneAccessGranted() else { return }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("figma-note-\(UUID().uuidString)")
            .appendingPathExtension("m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.prepareToRecord()
            guard recorder?.record() == true else {
                throw RecordingError.couldNotStart
            }
            recordingURL = url
            isRecording = true
        } catch {
            errorMessage = "Could not start the microphone: \(error.localizedDescription)"
            removeRecording()
        }
    }

    func stopAndTranscribe(apiKey: String) async {
        guard let url = recordingURL else { return }
        recorder?.stop()
        recorder = nil
        isRecording = false
        isTranscribing = true
        defer {
            isTranscribing = false
            removeRecording()
        }

        do {
            transcript = try await transcribe(audioAt: url, apiKey: apiKey)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func microphoneAccessGranted() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .notDetermined:
            let granted = await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { continuation.resume(returning: $0) }
            }
            if !granted {
                errorMessage = "Allow Microphone access in System Settings to record notes."
            }
            return granted
        default:
            errorMessage = "Allow Microphone access in System Settings to record notes."
            return false
        }
    }

    private func transcribe(audioAt url: URL, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else { throw RecordingError.missingAPIKey }
        let audioData = try Data(contentsOf: url)
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        body.appendFormField(name: "model", value: "gpt-4o-mini-transcribe", boundary: boundary)
        body.appendFile(name: "file", filename: "note.m4a", mimeType: "audio/mp4", data: audioData, boundary: boundary)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw RecordingError.invalidResponse }
        guard 200..<300 ~= http.statusCode else {
            let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? [String: Any]
            throw RecordingError.api(message?["message"] as? String ?? "OpenAI transcription failed (\(http.statusCode)).")
        }
        guard let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = payload["text"] as? String,
              !text.isEmpty else {
            throw RecordingError.invalidResponse
        }
        return text
    }

    private func removeRecording() {
        if let recordingURL {
            try? FileManager.default.removeItem(at: recordingURL)
        }
        recordingURL = nil
    }

    private enum RecordingError: LocalizedError {
        case couldNotStart, missingAPIKey, invalidResponse, api(String)

        var errorDescription: String? {
            switch self {
            case .couldNotStart: "The microphone could not start recording."
            case .missingAPIKey: "Add an OpenAI API key in Settings before transcribing notes."
            case .invalidResponse: "OpenAI returned an unreadable transcription."
            case .api(let message): message
            }
        }
    }
}

private extension Data {
    mutating func appendFormField(name: String, value: String, boundary: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        append("\(value)\r\n".data(using: .utf8)!)
    }

    mutating func appendFile(name: String, filename: String, mimeType: String, data: Data, boundary: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        append(data)
        append("\r\n".data(using: .utf8)!)
    }
}
