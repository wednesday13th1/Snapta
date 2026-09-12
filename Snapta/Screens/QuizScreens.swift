import SwiftUI
import AVFoundation

struct WordMeaningContent: View {
    let entry: KarutaEntry

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 8) {
                if !entry.reading.isEmpty {
                    Text(entry.reading).font(.subheadline).foregroundStyle(SnaptaTheme.ink.opacity(0.6))
                }
                Text(entry.word)
                    .font(SnaptaTheme.mincho(44, weight: .semibold))
                    .foregroundStyle(SnaptaTheme.indigo)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }.frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 16) {
                section("どんな意味かな？", text: entry.meaningText)
                if let explanation = entry.explanationText { section("もう少し知ろう", text: explanation) }
                if let example = entry.exampleText { section("使い方も見てみよう", text: "「\(example)」") }
                if let note = entry.note, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    section("写真のメモ", text: note)
                }
            }
            if let image = entry.image {
                Image(uiImage: image).resizable().scaledToFit()
                    .frame(maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .accessibilityLabel("自分で見つけた\(entry.word)の写真")
            }
        }
    }

    private func section(_ title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.subheadline.weight(.bold)).foregroundStyle(SnaptaTheme.moss)
            Text(text).font(.body).foregroundStyle(SnaptaTheme.ink).lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SavedScreen: View {
    @ObservedObject var flow: LearningFlow

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                VStack(spacing: 10) {
                    Text("まずは、この言葉を知ってみよう！")
                        .font(SnaptaTheme.mincho(22, weight: .semibold))
                        .foregroundStyle(SnaptaTheme.indigo)
                    Text("意味や使い方を見てから、カルタに挑戦しよう。")
                        .font(.subheadline).foregroundStyle(SnaptaTheme.ink.opacity(0.65))
                }.multilineTextAlignment(.center)
                PaperPanel { WordMeaningContent(entry: flow.currentEntry) }
            }.padding(.horizontal, 20).padding(.vertical, 24)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrimaryButton("意味がわかった！カルタへ", icon: "rectangle.stack.fill") {
                flow.go(.quiz)
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
            .background(SnaptaTheme.paper)
        }
    }
}

struct QuizScreen: View {
    @ObservedObject var flow: LearningFlow
    @StateObject private var speechService = JapaneseSpeechService()
    @StateObject private var game: KarutaGameViewModel
    @AppStorage("snapta.karuta.isMuted") private var isMuted = false

    init(flow: LearningFlow) {
        self.flow = flow
        _game = StateObject(wrappedValue: KarutaGameViewModel(entries: flow.learnedEntries, initialID: flow.currentEntryID))
    }

    var body: some View {
        Group {
            if game.phase == .finished {
                KarutaResultView(result: game.result, close: { flow.reset() })
            } else {
                KarutaGameView(game: game, isMuted: $isMuted)
            }
        }
        .task(id: game.currentEntry.id) { await speakQuestion() }
        .onChange(of: isMuted) { _, muted in
            if muted {
                speechService.stop()
                game.questionDidFinishSpeaking()
            }
        }
    }

    private func speakQuestion() async {
        guard !isMuted else {
            game.questionDidFinishSpeaking()
            return
        }
        if await speechService.speakText(game.currentEntry.meaningText) {
            game.questionDidFinishSpeaking()
        }
    }
}

private struct KarutaGameView: View {
    @ObservedObject var game: KarutaGameViewModel
    @Binding var isMuted: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @State private var collisionCardID: UUID?
    @State private var showsIncorrectFeedback = false
    @State private var incorrectFeedbackID = UUID()

    var body: some View {
        VStack(spacing: 3) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(game.phase == .listening ? "よく聞いて…" : "正しい札を見つけよう！")
                        .font(SnaptaTheme.mincho(17, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(voiceOver ? "札を選び、上にスワイプして答えます" : "札を横へすばやく払おう")
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(SnaptaTheme.ink.opacity(0.55))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)
                Spacer()
                Button { isMuted.toggle() } label: {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 14)).frame(width: 36, height: 36)
                        .foregroundStyle(isMuted ? SnaptaTheme.vermilion : SnaptaTheme.indigo)
                        .background(SnaptaTheme.paperLight, in: Circle())
                }.accessibilityLabel(isMuted ? "音声をオンにする" : "音声をミュート")
            }.padding(.horizontal, 14).padding(.vertical, 2)

            if isMuted {
                Text(game.currentEntry.meaningText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(SnaptaTheme.ink.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .frame(maxWidth: 300)
                    .background(SnaptaTheme.paperLight.opacity(0.96), in: RoundedRectangle(cornerRadius: 7))
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(SnaptaTheme.line))
                    .accessibilityLabel("問題、\(game.currentEntry.meaningText)")
            }

            if showsIncorrectFeedback {
                Label("もう一度考えてみよう", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(SnaptaTheme.vermilion)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(SnaptaTheme.paperLight, in: Capsule())
                    .overlay(Capsule().stroke(SnaptaTheme.vermilion.opacity(0.35)))
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .accessibilityAddTraits(.isStaticText)
            }

            GeometryReader { proxy in
                let count = game.cards.count
                let columns = count <= 4 ? 2 : 3
                let rows = max(1, Int(ceil(Double(count) / Double(columns))))
                let width = min((proxy.size.width - 28) / CGFloat(columns), 132)
                let height = min(width / 0.67, (proxy.size.height - 18) / CGFloat(rows))
                let cardSize = CGSize(width: min(width, height * 0.67), height: height)
                let placements = KarutaBoardLayout.placements(count: count, in: proxy.size, cardSize: cardSize)

                ZStack {
                    ForEach(Array(game.cards.enumerated()), id: \.element.id) { index, entry in
                        KarutaInteractiveCard(
                            entry: entry,
                            size: cardSize,
                            boardWidth: proxy.size.width,
                            placement: placements[index],
                            enabled: game.acceptsInput,
                            reduceMotion: reduceMotion,
                            collisionPulse: collisionCardID == entry.id,
                            soundEnabled: !isMuted,
                            touched: { game.cardTouched(entry) },
                            submitted: { motion in handleSubmit(entry, motion: motion, index: index) }
                        )
                    }
                }.frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
    }

    private func handleSubmit(_ entry: KarutaEntry, motion: KarutaCardMotion, index: Int) -> Bool? {
        guard let correct = game.submit(entry) else { return nil }
        if correct {
            if game.cards.count > 1 {
                collisionCardID = game.cards[(index + (motion.direction > 0 ? 1 : game.cards.count - 1)) % game.cards.count].id
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(190)); collisionCardID = nil
                }
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(reduceMotion ? 330 : motion.animationMilliseconds + 215))
                game.advanceAfterCorrectCard()
            }
        } else {
            KarutaFeedback.incorrect()
            showIncorrectFeedback()
        }
        return correct
    }

    private func showIncorrectFeedback() {
        let feedbackID = UUID()
        incorrectFeedbackID = feedbackID
        withAnimation(.easeOut(duration: 0.18)) { showsIncorrectFeedback = true }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            guard incorrectFeedbackID == feedbackID else { return }
            withAnimation(.easeIn(duration: 0.18)) { showsIncorrectFeedback = false }
        }
    }
}

private struct KarutaCardView: View {
    let entry: KarutaEntry
    let border: Color

    var body: some View {
        GeometryReader { card in
            VStack(spacing: 0) {
                ZStack {
                    SnaptaTheme.paper
                    if let image = entry.image {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        Image(systemName: entry.symbol)
                            .font(.system(size: min(card.size.width * 0.38, 42), weight: .light))
                            .foregroundStyle(border.opacity(0.76))
                    }
                }.frame(width: card.size.width, height: card.size.height * 0.64).clipped()
                VStack(spacing: 2) {
                    Text(entry.reading).font(.system(size: 10, weight: .medium))
                        .foregroundStyle(SnaptaTheme.ink.opacity(0.48))
                    Text(entry.word).font(SnaptaTheme.mincho(20, weight: .semibold))
                        .foregroundStyle(SnaptaTheme.ink)
                }
                .lineLimit(1).minimumScaleFactor(0.62).padding(.horizontal, 7)
                .frame(width: card.size.width, height: card.size.height * 0.36)
            }
        }
        .background(SnaptaTheme.paperLight).padding(4).background(.white).padding(5).background(border)
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay { Canvas { context, size in
            for i in 0..<22 {
                let x = CGFloat((i * 37) % 101) / 101 * size.width
                let y = CGFloat((i * 61) % 97) / 97 * size.height
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)), with: .color(SnaptaTheme.ink.opacity(0.035)))
            }
        }.allowsHitTesting(false) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.reading)、\(entry.word)の札")
        .accessibilityHint("タップまたは横にスワイプして答える")
        .accessibilityAddTraits(.isButton)
    }
}

private struct KarutaCardMotion {
    let direction: CGFloat
    let speed: CGFloat
    let horizontalTranslation: CGFloat
    let destination: CGFloat
    let duration: Double
    let rotation: Double
    var animationMilliseconds: Int { Int(duration * 1_000) }

    init(value: DragGesture.Value) {
        let projected = value.predictedEndTranslation.width - value.translation.width
        let horizontalSpeed = abs(projected) * 7.5
        direction = (abs(value.predictedEndTranslation.width) > 1 ? value.predictedEndTranslation.width : value.translation.width) >= 0 ? 1 : -1
        speed = horizontalSpeed
        horizontalTranslation = value.translation.width
        destination = min(900, max(210, abs(value.predictedEndTranslation.width) + horizontalSpeed * 0.22)) * direction
        duration = min(0.42, max(0.18, 0.44 - Double(horizontalSpeed / 4_500)))
        rotation = Double(direction) * min(11, max(3, Double(horizontalSpeed / 150)))
    }

    init(accessibilityDirection: CGFloat) {
        direction = accessibilityDirection
        speed = 900
        horizontalTranslation = accessibilityDirection * 120
        destination = accessibilityDirection * 520
        duration = 0.28
        rotation = Double(accessibilityDirection) * 6
    }

    init(tapDirection: CGFloat, boardWidth: CGFloat) {
        direction = tapDirection
        speed = 1_150
        horizontalTranslation = tapDirection * 120
        destination = tapDirection * max(360, boardWidth * 1.05)
        duration = 0.27
        rotation = Double(tapDirection) * 8
    }


    var isDeliberateSwipe: Bool {
        abs(horizontalTranslation) >= 44 || (speed > 230 && destination.magnitude > 220)
    }
}

private struct KarutaInteractiveCard: View {
    private enum DisplayState { case idle, pressed, flying, wrongReturning }

    let entry: KarutaEntry
    let size: CGSize
    let boardWidth: CGFloat
    let placement: KarutaBoardPlacement
    let enabled: Bool
    let reduceMotion: Bool
    let collisionPulse: Bool
    let soundEnabled: Bool
    let touched: () -> Void
    let submitted: (KarutaCardMotion) -> Bool?
    @GestureState private var drag = CGSize.zero
    @GestureState private var pressing = false
    @State private var settledOffset = CGSize.zero
    @State private var throwRotation = 0.0
    @State private var opacity = 1.0
    @State private var shake = 0.0
    @State private var touchRegistered = false
    @State private var displayState: DisplayState = .idle

    private var border: Color {
        [SnaptaTheme.vermilion, SnaptaTheme.indigo, SnaptaTheme.moss,
         Color(red: 0.42, green: 0.31, blue: 0.48), Color(red: 0.39, green: 0.28, blue: 0.20)][abs(entry.id.hashValue) % 5]
    }

    var body: some View {
        KarutaCardView(entry: entry, border: border)
            .frame(width: max(44, size.width - 18), height: max(66, size.height - 18))
            .scaleEffect(displayState == .pressed || pressing ? 0.97 : 1)
            .shadow(color: SnaptaTheme.ink.opacity(displayState == .pressed || pressing ? 0.025 : 0.08), radius: displayState == .pressed || pressing ? 0.5 : 1.5, y: displayState == .pressed || pressing ? 0 : 1)
            .rotationEffect(.degrees(placement.rotation + throwRotation + shake + (collisionPulse ? 1.4 : 0)))
            .offset(x: placement.offset.width + settledOffset.width + drag.width + (collisionPulse ? 4 : 0),
                    y: placement.offset.height + settledOffset.height + drag.height * 0.35)
            .opacity(opacity)
            .animation(.easeOut(duration: 0.1), value: pressing)
            .animation(.spring(response: 0.22, dampingFraction: 0.48), value: collisionPulse)
            .gesture(dragGesture)
            .onTapGesture { tapCard() }
            .accessibilityAction { accessibilitySubmit() }
            .allowsHitTesting(enabled)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .local)
            .updating($pressing) { _, state, _ in state = true }
            .updating($drag) { value, state, _ in state = value.translation }
            .onChanged { _ in
                guard !touchRegistered else { return }
                touchRegistered = true
                displayState = .pressed
                touched()
            }
            .onEnded { value in
                touchRegistered = false
                let motion = KarutaCardMotion(value: value)
                if motion.isDeliberateSwipe {
                    resolve(motion)
                } else {
                    returnHome()
                }
            }
    }

    private func resolve(_ motion: KarutaCardMotion, pressDelay: Bool = false) {
        guard let correct = submitted(motion) else { returnHome(); return }
        let delay = pressDelay ? 0.075 : 0
        withAnimation(.easeOut(duration: 0.075)) { displayState = .pressed }
        Task { @MainActor in
            if delay > 0 { try? await Task.sleep(for: .milliseconds(75)) }
            correct ? flyAway(motion) : reject(motion)
        }
    }

    private func flyAway(_ motion: KarutaCardMotion) {
        displayState = .flying
        // Trigger at the exact state change that starts the card's flight.
            KarutaFeedback.correct(playSound: soundEnabled)
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.2)) { settledOffset.width = motion.direction * 50; opacity = 0 }
        } else {
            withAnimation(.easeOut(duration: motion.duration)) {
                settledOffset.width = motion.destination; settledOffset.height = -min(35, motion.speed * 0.018)
                throwRotation = motion.rotation; opacity = 0.86
            }
        }
    }

    private func reject(_ motion: KarutaCardMotion) {
        displayState = .wrongReturning
        withAnimation(.easeOut(duration: 0.055)) { settledOffset.width = -5 }
        withAnimation(.easeInOut(duration: 0.065).delay(0.055)) { settledOffset.width = 5 }
        withAnimation(.easeInOut(duration: 0.055).delay(0.12)) { settledOffset.width = -2 }
        withAnimation(.easeOut(duration: 0.065).delay(0.175)) { settledOffset = .zero; displayState = .idle }
    }

    private func returnHome() { withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) { settledOffset = .zero; displayState = .idle } }
    private func tapCard() {
        guard enabled else { return }
        touched()
        let direction: CGFloat = placement.offset.width < -8 ? -1 : 1
        resolve(KarutaCardMotion(tapDirection: direction, boardWidth: boardWidth), pressDelay: true)
    }
    private func accessibilitySubmit() {
        guard enabled else { return }
        touched()
        let synthetic = KarutaCardMotion(accessibilityDirection: 1)
        if let correct = submitted(synthetic) { correct ? flyAway(synthetic) : reject(synthetic) }
    }
}

private enum KarutaFeedback {
    @MainActor
    private final class FlickSoundPlayer {
        static let shared = FlickSoundPlayer()
        private var player: AVAudioPlayer?

        private init() {
            guard let url = Bundle.main.url(forResource: "karuta_flick", withExtension: "wav")
                    ?? Bundle.main.url(forResource: "karuta_flick", withExtension: "m4a") else {
                // Safe silent fallback until the real, licensed paper-card recording is bundled.
                return
            }
            player = try? AVAudioPlayer(contentsOf: url)
            player?.volume = 0.38
            player?.prepareToPlay()
        }

        func playOnce() {
            guard let player else { return }
            // A correct answer can only submit once, but this also prevents accidental overlap.
            if player.isPlaying { player.stop() }
            player.currentTime = 0
            player.play()
        }
    }

    @MainActor
    static func correct(playSound: Bool) {
        if playSound { FlickSoundPlayer.shared.playOnce() }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred(intensity: 0.32)
    }
    static func incorrect() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred(intensity: 0.25)
    }
}

private struct KarutaResultView: View {
    let result: KarutaGameResult
    let close: () -> Void
    var body: some View {
        ScrollView {
            PaperPanel {
                VStack(spacing: 18) {
                    Text("きょうの記録").font(SnaptaTheme.mincho(27, weight: .semibold))
                    HStack { metric("正解", "\(result.correctCount)枚"); metric("正答率", result.accuracy.formatted(.percent.precision(.fractionLength(0)))) }
                    HStack { metric("平均", seconds(result.average)); metric("ベスト", seconds(result.best?.reactionTime ?? 0)) }
                    HStack { metric("連続正解", "\(result.bestStreak)回"); metric("速さ", ReactionSpeedEvaluator.evaluate(result.best?.reactionTime ?? 99).rawValue) }
                    if let best = result.best { row("最も速く取れた札", "\(best.word)  \(seconds(best.reactionTime))") }
                    if let slowest = result.slowest { row("まだ時間がかかる言葉", "\(slowest.word)  \(seconds(slowest.reactionTime))") }
                    Text("速さは、言葉が見た瞬間に浮かぶようになった変化の目安です。")
                        .font(.system(size: 13)).foregroundStyle(SnaptaTheme.ink.opacity(0.55)).multilineTextAlignment(.center)
                    PrimaryButton("おわる", icon: "checkmark", action: close)
                }
            }.padding(20)
        }
    }
    private func metric(_ title: String, _ value: String) -> some View { VStack(spacing: 5) { Text(title).font(.system(size: 11, weight: .bold)).foregroundStyle(SnaptaTheme.ink.opacity(0.5)); Text(value).font(SnaptaTheme.mincho(21, weight: .semibold)) }.frame(maxWidth: .infinity).padding(12).background(SnaptaTheme.paper) }
    private func row(_ title: String, _ value: String) -> some View { HStack { Text(title); Spacer(); Text(value).fontWeight(.bold) }.font(.system(size: 13)).padding(.vertical, 3) }
    private func seconds(_ value: TimeInterval) -> String { String(format: "%.2f秒", value) }
}
