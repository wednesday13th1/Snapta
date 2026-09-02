import AVFoundation

enum JapaneseSpeechMode {
    case word
    case explanation
}

/// Owns Japanese speech synthesis so views never need to prepare or transform pronunciation text.
@MainActor
final class JapaneseSpeechService: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var activeUtterance: AVSpeechUtterance?
    private var activeID: UUID?
    private var continuation: CheckedContinuation<Bool, Never>?

    init() {
        synthesizer.delegate = delegate
    }

    private lazy var delegate = JapaneseSpeechDelegate { [weak self] utterance, finished in
        guard let self, utterance === activeUtterance else { return }
        activeUtterance = nil
        activeID = nil
        continuation?.resume(returning: finished)
        continuation = nil
    }

    /// Uses the explicit reading without character-by-character conversion. An empty reading safely falls back to the display word.
    func speakWord(_ entry: KarutaEntry) async -> Bool {
        await speakText(Self.speechText(for: entry), mode: .word)
    }

    /// Reads Japanese prose such as a meaning or example at a natural sentence speed.
    func speakText(_ text: String, mode: JapaneseSpeechMode = .explanation) async -> Bool {
        stop()

        guard let japaneseVoice = AVSpeechSynthesisVoice(language: "ja-JP") else {
            assertionFailure("A ja-JP speech voice is not installed on this device.")
            return false
        }

        // Keep small kana such as ゃゅょっ intact by passing the complete string directly to AVFoundation.
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = japaneseVoice
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        switch mode {
        case .word:
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        case .explanation:
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        }

        let utteranceID = UUID()
        activeUtterance = utterance
        activeID = utteranceID

        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                self.continuation = continuation
                synthesizer.speak(utterance)
            }
        } onCancel: { [weak self] in
            Task { @MainActor in
                self?.cancel(utteranceID)
            }
        }
    }

    func stop() {
        activeUtterance = nil
        activeID = nil
        continuation?.resume(returning: false)
        continuation = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    static func speechText(for entry: KarutaEntry) -> String {
        entry.reading.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? entry.word
            : entry.reading
    }

    private func cancel(_ utteranceID: UUID) {
        guard utteranceID == activeID else { return }
        stop()
    }
}

private final class JapaneseSpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    let completion: (AVSpeechUtterance, Bool) -> Void

    init(completion: @escaping (AVSpeechUtterance, Bool) -> Void) {
        self.completion = completion
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        completion(utterance, true)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        completion(utterance, false)
    }
}
