import AVFoundation
import Combine
import Speech

@MainActor
final class SpeechTranscriptionService: NSObject, ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var transcript = ""
    @Published private(set) var errorMessage: String?

    private let audioEngine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: .current)
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isStopping = false
    private var hasInputTap = false

    func start() async {
        transcript = ""
        errorMessage = nil
        isStopping = false

        guard await requestPermissions() else { return }
        guard let recognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognition is not available for the current system language."
            return
        }

        do {
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            recognitionRequest = request

            let inputNode = audioEngine.inputNode
            if hasInputTap {
                inputNode.removeTap(onBus: 0)
                hasInputTap = false
            }
            let format = inputNode.outputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else {
                errorMessage = "No microphone input is available. Check your selected input device and try again."
                recognitionRequest = nil
                return
            }
            inputNode.installTap(onBus: 0, bufferSize: 1_024, format: format) { [weak request] buffer, _ in
                request?.append(buffer)
            }
            hasInputTap = true

            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true

            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor [weak self] in
                    if let result {
                        self?.transcript = result.bestTranscription.formattedString
                    }
                    if let error, self?.isStopping == false {
                        self?.errorMessage = error.localizedDescription
                        self?.stop()
                    } else if result?.isFinal == true {
                        self?.stop()
                    }
                }
            }
        } catch {
            errorMessage = "Could not start the microphone: \(error.localizedDescription)"
            stop()
        }
    }

    func stop() {
        guard isRecording || recognitionRequest != nil else { return }
        isStopping = true
        audioEngine.stop()
        if hasInputTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInputTap = false
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false
    }

    private func requestPermissions() async -> Bool {
        let speechAuthorized = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        guard speechAuthorized else {
            errorMessage = "Allow Speech Recognition in System Settings to use dictation."
            return false
        }

        let microphoneAuthorized = await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
        guard microphoneAuthorized else {
            errorMessage = "Allow Microphone access in System Settings to use dictation."
            return false
        }
        return true
    }
}
