import SwiftUI
import UIKit

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
    var example: String?
    var explanation: String?

    var image: UIImage? { imageData.flatMap(UIImage.init(data:)) }
    var meaningText: String {
        meaning.flatMap { $0.isEmpty ? nil : $0 }
            ?? note.flatMap { $0.isEmpty ? nil : $0 }
            ?? imageTitle
    }
    private var starter: KarutaEntry? {
        guard !isUserCreated else { return nil }
        return LearningFlow.starterEntries.first { $0.word == word }
    }
    var explanationText: String? { nonempty(explanation) ?? nonempty(starter?.explanation) }
    var exampleText: String? { nonempty(example) ?? nonempty(starter?.example) }
    private func nonempty(_ text: String?) -> String? {
        guard let value = text?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return value
    }
    var categoryText: String { category.flatMap { $0.isEmpty ? nil : $0 } ?? "理科" }
    var isLearned: Bool { imageData != nil }
}
