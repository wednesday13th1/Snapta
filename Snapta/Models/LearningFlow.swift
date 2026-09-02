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
    var category: String?
    var note: String?
    var learnedAt: Date?

    var image: UIImage? { imageData.flatMap(UIImage.init(data:)) }
    var meaningText: String { meaning.flatMap { $0.isEmpty ? nil : $0 } ?? "写真と結びつけて覚えることばです。" }
    var categoryText: String { category.flatMap { $0.isEmpty ? nil : $0 } ?? "理科" }
    var isLearned: Bool { imageData != nil }
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
        KarutaEntry(word: "反射", reading: "はんしゃ", imageTitle: "水たまり", symbol: "drop.fill", meaning: "光がものに当たって、はね返ること。", category: "理科"),
        KarutaEntry(word: "蒸発", reading: "じょうはつ", imageTitle: "湯気", symbol: "cloud.fill", meaning: "液体が気体に変わること。", category: "理科"),
        KarutaEntry(word: "対称", reading: "たいしょう", imageTitle: "ちょう", symbol: "butterfly.fill", meaning: "折ったとき、形がぴったり重なること。", category: "算数・数学"),
        KarutaEntry(word: "循環", reading: "じゅんかん", imageTitle: "水のめぐり", symbol: "arrow.triangle.2.circlepath", meaning: "ひとめぐりして、また元へ戻ること。", category: "理科"),
        KarutaEntry(word: "摩擦", reading: "まさつ", imageTitle: "こする手", symbol: "hands.sparkles.fill", meaning: "ものの動きをさまたげる力。", category: "理科"),
        KarutaEntry(word: "透明", reading: "とうめい", imageTitle: "ガラス", symbol: "square.on.square", meaning: "向こう側が透けて見えること。", category: "身の回り"),
        KarutaEntry(word: "重力", reading: "じゅうりょく", imageTitle: "落ちるりんご", symbol: "arrow.down", meaning: "ものを地面の方へ引っぱる力。", category: "理科")
    ]

    init() {
        let initialEntries: [KarutaEntry]
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([KarutaEntry].self, from: data), !saved.isEmpty {
            initialEntries = saved
        } else {
            initialEntries = Self.starterEntries
        }
        entries = initialEntries
        currentEntryID = initialEntries[0].id
    }

    var currentEntry: KarutaEntry { entries.first(where: { $0.id == currentEntryID }) ?? entries[0] }
    var word: String { currentEntry.word }
    var learnedEntries: [KarutaEntry] { entries.filter(\.isLearned) }

    func select(_ entry: KarutaEntry) {
        currentEntryID = entry.id
        capturedImage = entry.image
    }

    func addWord(word: String, reading: String, meaning: String, category: String) {
        let entry = KarutaEntry(
            word: word.trimmingCharacters(in: .whitespacesAndNewlines),
            reading: reading.trimmingCharacters(in: .whitespacesAndNewlines),
            imageTitle: "自分で見つけた写真", symbol: "viewfinder", isUserCreated: true,
            meaning: meaning.trimmingCharacters(in: .whitespacesAndNewlines), category: category
        )
        entries.append(entry)
        select(entry)
        persist()
    }

    func addEntry(word: String, reading: String, imageTitle: String, meaning: String, image: UIImage) {
        let entry = KarutaEntry(
            word: word.trimmingCharacters(in: .whitespacesAndNewlines),
            reading: reading.trimmingCharacters(in: .whitespacesAndNewlines),
            imageTitle: imageTitle.trimmingCharacters(in: .whitespacesAndNewlines), symbol: "photo.fill",
            imageData: image.jpegData(compressionQuality: 0.82), isUserCreated: true,
            meaning: meaning.trimmingCharacters(in: .whitespacesAndNewlines), category: "身の回り", learnedAt: Date()
        )
        entries.append(entry)
        select(entry)
        persist()
    }

    func updateNote(_ note: String) {
        guard let index = entries.firstIndex(where: { $0.id == currentEntryID }) else { return }
        entries[index].note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        persist()
    }

    func saveCapturedImage() {
        guard let capturedImage, let index = entries.firstIndex(where: { $0.id == currentEntryID }) else { return }
        entries[index].imageData = capturedImage.jpegData(compressionQuality: 0.82)
        entries[index].learnedAt = Date()
        persist()
    }

    func go(_ next: LearningStep) { withAnimation(.easeInOut(duration: 0.3)) { step = next } }
    func reset() {
        selectedAnswer = nil
        capturedImage = currentEntry.image
        quizMessage = nil
        quizCompleted = false
        go(.today)
    }
    func answer(_ entry: KarutaEntry) {
        selectedAnswer = entry.id
        quizCompleted = entry.id == currentEntryID
        quizMessage = quizCompleted ? "正解！ ことばと写真がそろったよ" : "もう一度考えてみよう"
    }
    func nextQuizWord() {
        let choices = learnedEntries
        guard !choices.isEmpty else { return }
        if let currentIndex = choices.firstIndex(where: { $0.id == currentEntryID }) {
            select(choices[(currentIndex + 1) % choices.count])
        } else if let first = choices.first {
            select(first)
        }
        selectedAnswer = nil
        quizMessage = nil
        quizCompleted = false
    }
    private func persist() {
        if let data = try? JSONEncoder().encode(entries) { UserDefaults.standard.set(data, forKey: storageKey) }
    }
}
