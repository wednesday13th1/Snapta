import Foundation
import Combine

struct DailySummary: Identifiable, Equatable {
    let date: Date
    let registeredCount: Int

    var id: Date { date }
}

@MainActor
final class DailyProgressManager: ObservableObject {
    @Published private(set) var dailyRegisteredCount: Int
    @Published private(set) var pendingSummary: DailySummary?

    private enum Key {
        static let lastActiveDate = "snapta.daily.lastActiveDate"
        static let registeredCount = "snapta.daily.registeredCount"
        static let previousRegisteredCount = "snapta.daily.previousRegisteredCount"
        static let lastSummaryShownDate = "snapta.daily.lastSummaryShownDate"
        static let currentWordID = "snapta.daily.currentWordID"
    }

    private let defaults: UserDefaults
    private let calendar: Calendar

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
        dailyRegisteredCount = defaults.integer(forKey: Key.registeredCount)
    }

    var currentDailyWordID: UUID? {
        guard let value = defaults.string(forKey: Key.currentWordID) else { return nil }
        return UUID(uuidString: value)
    }

    /// Returns true only when a previously initialized day changed.
    @discardableResult
    func checkForNewDay(currentDate: Date = Date()) -> Bool {
        let today = calendar.startOfDay(for: currentDate)

        guard let storedDate = defaults.object(forKey: Key.lastActiveDate) as? Date else {
            defaults.set(today, forKey: Key.lastActiveDate)
            dailyRegisteredCount = defaults.integer(forKey: Key.registeredCount)
            return false
        }

        let lastActiveDay = calendar.startOfDay(for: storedDate)
        guard !calendar.isDate(lastActiveDay, inSameDayAs: today) else { return false }

        let previousCount = defaults.integer(forKey: Key.registeredCount)
        defaults.set(previousCount, forKey: Key.previousRegisteredCount)
        defaults.set(0, forKey: Key.registeredCount)
        defaults.set(today, forKey: Key.lastActiveDate)
        dailyRegisteredCount = 0

        let shownDate = defaults.object(forKey: Key.lastSummaryShownDate) as? Date
        if shownDate.map({ calendar.isDate($0, inSameDayAs: today) }) != true {
            pendingSummary = DailySummary(date: today, registeredCount: previousCount)
        }
        return true
    }

    func recordRegistration(currentDate: Date = Date()) {
        checkForNewDay(currentDate: currentDate)
        dailyRegisteredCount += 1
        defaults.set(dailyRegisteredCount, forKey: Key.registeredCount)
    }

    func setCurrentDailyWordID(_ id: UUID?) {
        if let id {
            defaults.set(id.uuidString, forKey: Key.currentWordID)
        } else {
            defaults.removeObject(forKey: Key.currentWordID)
        }
    }

    func markSummaryAsShown() {
        guard let summary = pendingSummary else { return }
        defaults.set(summary.date, forKey: Key.lastSummaryShownDate)
        pendingSummary = nil
    }
}
