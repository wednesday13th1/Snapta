import SwiftUI

struct KarutaReactionRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let entryID: UUID
    let word: String
    let reactionTime: TimeInterval
    let answeredAt: Date

    init(entry: KarutaEntry, reactionTime: TimeInterval, answeredAt: Date = .now) {
        id = UUID()
        entryID = entry.id
        word = entry.word
        self.reactionTime = reactionTime
        self.answeredAt = answeredAt
    }
}

enum ReactionSpeed: String {
    case flash = "一閃"
    case fast = "速い"
    case steady = "いい調子"
    case growing = "もう少し"
}

enum ReactionSpeedEvaluator {
    static func evaluate(_ seconds: TimeInterval) -> ReactionSpeed {
        switch seconds {
        case ..<1: .flash
        case ..<2: .fast
        case ..<3: .steady
        default: .growing
        }
    }
}

@MainActor
final class ReactionTimeTracker {
    private(set) var questionStartTime: ContinuousClock.Instant?
    private(set) var correctCardTouchTime: ContinuousClock.Instant?

    func questionDidFinishSpeaking() {
        questionStartTime = .now
        correctCardTouchTime = nil
    }

    func touchCorrectCard() -> TimeInterval? {
        guard correctCardTouchTime == nil, let start = questionStartTime else { return nil }
        let now = ContinuousClock.now
        correctCardTouchTime = now
        return Double(start.duration(to: now).components.attoseconds) / 1e18
            + Double(start.duration(to: now).components.seconds)
    }
}

struct KarutaGameResult {
    let answers: [KarutaReactionRecord]
    let attempts: Int
    let bestStreak: Int

    var correctCount: Int { answers.count }
    var accuracy: Double { attempts == 0 ? 0 : Double(correctCount) / Double(attempts) }
    var average: TimeInterval { answers.isEmpty ? 0 : answers.map(\.reactionTime).reduce(0, +) / Double(answers.count) }
    var best: KarutaReactionRecord? { answers.min(by: { $0.reactionTime < $1.reactionTime }) }
    var slowest: KarutaReactionRecord? { answers.max(by: { $0.reactionTime < $1.reactionTime }) }
}

@MainActor
final class KarutaGameViewModel: ObservableObject {
    enum Phase { case listening, playing, transitioning, finished }

    @Published private(set) var cards: [KarutaEntry]
    @Published private(set) var currentEntry: KarutaEntry
    @Published private(set) var phase: Phase = .listening
    @Published private(set) var records: [KarutaReactionRecord] = []
    @Published private(set) var attempts = 0
    @Published private(set) var bestStreak = 0
    @Published private(set) var contactCardID: UUID?

    private let tracker = ReactionTimeTracker()
    private var questionIndex = 0
    private var streak = 0
    private var pendingReaction: TimeInterval?
    private let historyKey = "snapta.karuta.reactions.v1"

    init(entries: [KarutaEntry], initialID: UUID) {
        let playable = entries.isEmpty ? [LearningFlow.starterEntries[0]] : entries
        cards = playable
        currentEntry = playable.first(where: { $0.id == initialID }) ?? playable[0]
    }

    var result: KarutaGameResult { .init(answers: records, attempts: attempts, bestStreak: bestStreak) }
    var acceptsInput: Bool { phase == .playing }

    func questionDidFinishSpeaking() {
        guard phase == .listening else { return }
        tracker.questionDidFinishSpeaking()
        phase = .playing
    }

    func cardTouched(_ entry: KarutaEntry) {
        guard acceptsInput else { return }
        contactCardID = entry.id
        if entry.id == currentEntry.id, pendingReaction == nil {
            pendingReaction = tracker.touchCorrectCard()
        }
    }

    func submit(_ entry: KarutaEntry) -> Bool? {
        guard acceptsInput else { return nil }
        attempts += 1
        contactCardID = nil
        guard entry.id == currentEntry.id else {
            streak = 0
            return false
        }
        phase = .transitioning
        streak += 1
        bestStreak = max(bestStreak, streak)
        let reaction = pendingReaction ?? tracker.touchCorrectCard() ?? 0
        let record = KarutaReactionRecord(entry: entry, reactionTime: max(0, reaction))
        records.append(record)
        persist(record)
        return true
    }

    func advanceAfterCorrectCard() {
        guard phase == .transitioning else { return }
        questionIndex += 1
        if questionIndex >= cards.count {
            phase = .finished
            return
        }
        let remaining = cards.filter { candidate in !records.contains(where: { $0.entryID == candidate.id }) }
        currentEntry = remaining.first ?? cards[questionIndex % cards.count]
        pendingReaction = nil
        phase = .listening
    }

    private func persist(_ record: KarutaReactionRecord) {
        var history = (UserDefaults.standard.data(forKey: historyKey))
            .flatMap { try? JSONDecoder().decode([KarutaReactionRecord].self, from: $0) } ?? []
        history.append(record)
        if let data = try? JSONEncoder().encode(Array(history.suffix(500))) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }
}

struct KarutaBoardPlacement: Equatable {
    let offset: CGSize
    let rotation: Double
}

enum KarutaBoardLayout {
    static func placements(count: Int, in size: CGSize, cardSize: CGSize) -> [KarutaBoardPlacement] {
        guard count > 0 else { return [] }
        let columns = count <= 4 ? 2 : 3
        let rows = Int(ceil(Double(count) / Double(columns)))
        let horizontalRoom = max(0, size.width - cardSize.width * CGFloat(columns))
        let verticalRoom = max(0, size.height - cardSize.height * CGFloat(rows))
        let xGap = min(20, horizontalRoom / CGFloat(max(columns - 1, 1)))
        let yGap = min(22, verticalRoom / CGFloat(max(rows - 1, 1)))
        let boardHeight = cardSize.height * CGFloat(rows) + yGap * CGFloat(rows - 1)
        let topBias = max(4, (size.height - boardHeight) * 0.28)

        return (0..<count).map { index in
            let row = index / columns
            let column = index % columns
            let cellsInRow = min(columns, count - row * columns)
            let rowWidth = cardSize.width * CGFloat(cellsInRow) + xGap * CGFloat(cellsInRow - 1)
            let deterministicX = CGFloat(((index * 17) % 7) - 3) * 1.35
            let deterministicY = CGFloat(((index * 11) % 5) - 2) * 1.8
            let x = (size.width - rowWidth) / 2 + CGFloat(column) * (cardSize.width + xGap)
                + cardSize.width / 2 - size.width / 2 + deterministicX
            let y = topBias + CGFloat(row) * (cardSize.height + yGap)
                + cardSize.height / 2 - size.height / 2 + deterministicY
            return KarutaBoardPlacement(offset: .init(width: x, height: y), rotation: Double((index * 13) % 9 - 4) / 2.2)
        }
    }
}
