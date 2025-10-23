import Foundation
import Speech
import AVFoundation

class SpeechManager: NSObject, ObservableObject {
    @Published var recognizedText: String = ""
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var restartTimer: Timer?
    private var isListening = false
    
    // MARK: - Start Listening
    func startListening() {
        guard !isListening else { return }
        isListening = true
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                DispatchQueue.main.async {
                    self.startRecording()
                }
            default:
                print("Speech recognition authorization denied or not available.")
            }
        }
    }
    
    // MARK: - Stop Listening
    func stopListening() {
        isListening = false
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        restartTimer?.invalidate()
    }
    
    // MARK: - Restart Listening Automatically
    private func restartIfNeeded() {
        guard isListening else { return }
        restartTimer?.invalidate()
        restartTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            self.startRecording()
        }
    }
    
    // MARK: - Recording
    private func startRecording() {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session error: \(error)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("AudioEngine couldn't start: \(error)")
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                let text = result.bestTranscription.formattedString.lowercased()
                DispatchQueue.main.async {
                    self.recognizedText = text
                }
            }
            
            if error != nil || (result?.isFinal ?? false) {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.restartIfNeeded()
            }
        }
    }
}
