import SwiftUI
import UIKit

enum LearningStep: Int, CaseIterable { case today, camera, saved, quiz, flashcards }

struct KarutaEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var word: String
    var reading: String
    var imageTitle: String
    var symbol: String
    var imageData: Data?
    var isUserCreated = false
    var meaning: String?
    var image: UIImage? { imageData.flatMap(UIImage.init(data:)) }
    var meaningText: String { meaning?.isEmpty == false ? meaning! : "自分で見つけた写真と結びつけて覚えることばです。" }
}

@MainActor
final class LearningFlow: ObservableObject {
    @Published var step: LearningStep = .today
    @Published var entries: [KarutaEntry]
    @Published var currentEntryID: UUID
    @Published var selectedAnswer: UUID?
    @Published var capturedImage: UIImage?
    @Published var quizMessage: String?
    @Published var quizCompleted = false

    private let storageKey = "snapta.karuta.entries.v1"
    static let starterEntries = [
        KarutaEntry(word: "反射", reading: "はんしゃ", imageTitle: "水たまり", symbol: "drop.fill", meaning: "光がものに当たって、はね返ること。"),
        KarutaEntry(word: "蒸発", reading: "じょうはつ", imageTitle: "湯気", symbol: "cloud.fill", meaning: "液体が気体に変わること。"),
        KarutaEntry(word: "対称", reading: "たいしょう", imageTitle: "ちょう", symbol: "butterfly.fill", meaning: "折ったり線を引いたりしたとき、形がぴったり重なること。"),
        KarutaEntry(word: "循環", reading: "じゅんかん", imageTitle: "水のめぐり", symbol: "arrow.triangle.2.circlepath", meaning: "ひとめぐりして、また元へ戻ること。"),
        KarutaEntry(word: "摩擦", reading: "まさつ", imageTitle: "こする手", symbol: "hands.sparkles.fill", meaning: "もの同士が触れながら動くとき、動きをさまたげる力。"),
        KarutaEntry(word: "透明", reading: "とうめい", imageTitle: "ガラス", symbol: "square.on.square", meaning: "向こう側が透けて見えること。"),
        KarutaEntry(word: "重力", reading: "じゅうりょく", imageTitle: "落ちるりんご", symbol: "apple.logo", meaning: "ものを地面の方へ引っぱる力。")
    ]

    init() {
        let initialEntries: [KarutaEntry]
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([KarutaEntry].self, from: data), !saved.isEmpty {
            initialEntries = saved
        } else { initialEntries = Self.starterEntries }
        entries = initialEntries
        currentEntryID = initialEntries[0].id
    }

    var currentEntry: KarutaEntry { entries.first(where: { $0.id == currentEntryID }) ?? entries[0] }
    var word: String { currentEntry.word }

    func select(_ entry: KarutaEntry) {
        currentEntryID = entry.id
        capturedImage = entry.image
    }

    func addEntry(word: String, reading: String, imageTitle: String, meaning: String, image: UIImage) {
        let entry = KarutaEntry(
            word: word.trimmingCharacters(in: .whitespacesAndNewlines),
            reading: reading.trimmingCharacters(in: .whitespacesAndNewlines),
            imageTitle: imageTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            symbol: "photo.fill", imageData: image.jpegData(compressionQuality: 0.82), isUserCreated: true,
            meaning: meaning.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        entries.append(entry)
        currentEntryID = entry.id
        capturedImage = entry.image
        persist()
    }

    func saveCapturedImage() {
        guard let capturedImage, let index = entries.firstIndex(where: { $0.id == currentEntryID }) else { return }
        entries[index].imageData = capturedImage.jpegData(compressionQuality: 0.82)
        persist()
    }

    func go(_ next: LearningStep) { withAnimation(.easeInOut(duration: 0.35)) { step = next } }
    func reset() {
        selectedAnswer = nil; capturedImage = currentEntry.image; quizMessage = nil; quizCompleted = false; go(.today)
    }
    func answer(_ entry: KarutaEntry) {
        selectedAnswer = entry.id
        quizCompleted = entry.id == currentEntryID
        quizMessage = quizCompleted ? "正解！ ことばと写真がそろったよ" : "ちがう札みたい。もう一度探してみよう"
    }
    private func persist() {
        if let data = try? JSONEncoder().encode(entries) { UserDefaults.standard.set(data, forKey: storageKey) }
    }
}
