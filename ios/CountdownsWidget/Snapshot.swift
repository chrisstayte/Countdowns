import Foundation
import SwiftUI
import UIKit

let appGroup = "group.com.chrisstayte.countdowns"

/// One countdown as the Flutter app wrote it to `widget/snapshot.json`.
struct WidgetEvent: Codable, Identifiable, Hashable {
  let id: Int
  let title: String
  let target: TimeInterval
  let allDay: Bool
  let yearly: Bool
  let unit: String
  let font: String
  let text: String
  let colors: [String]
  let direction: String
  let icon: String?
  let photo: String?
  let photoWide: String?
  let darken: Double
  let createdAt: TimeInterval
}

struct WidgetSnapshot: Codable {
  let version: Int
  let events: [WidgetEvent]
}

enum SnapshotStore {
  static var folder: URL? {
    FileManager.default
      .containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
      .appendingPathComponent("widget", isDirectory: true)
  }

  static func load() -> [WidgetEvent] {
    guard let url = folder?.appendingPathComponent("snapshot.json"),
      let data = try? Data(contentsOf: url),
      let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    else { return [] }
    return snapshot.events
  }

  static func image(_ relative: String?) -> UIImage? {
    guard let relative, let url = folder?.appendingPathComponent(relative) else { return nil }
    return UIImage(contentsOfFile: url.path)
  }
}

// MARK: - Counting (mirrors lib/utilities/count_format.dart)

enum CountMode: String {
  case days, sleeps
}

struct Count {
  let big: String
  let unit: String
}

extension WidgetEvent {
  private var calendar: Calendar { Calendar.current }

  /// The next time it happens on or after `now` (yearly events roll over).
  func occurrence(at now: Date) -> Date {
    var date = Date(timeIntervalSince1970: target)
    guard yearly else { return date }
    while passed(date, at: now) {
      date = calendar.date(byAdding: .year, value: 1, to: date) ?? date
    }
    return date
  }

  private func passed(_ date: Date, at now: Date) -> Bool {
    if allDay {
      return calendar.startOfDay(for: now) > calendar.startOfDay(for: date)
    }
    return date <= now
  }

  func isToday(at now: Date) -> Bool {
    allDay && calendar.isDate(occurrence(at: now), inSameDayAs: now)
  }

  func isDone(at now: Date) -> Bool { !yearly && passed(occurrence(at: now), at: now) }

  func sleeps(at now: Date) -> Int {
    let from = calendar.startOfDay(for: now)
    let to = calendar.startOfDay(for: occurrence(at: now))
    return max(0, calendar.dateComponents([.day], from: from, to: to).day ?? 0)
  }

  func count(at now: Date, mode: CountMode) -> Count {
    if isDone(at: now) { return Count(big: "0", unit: "days") }
    if isToday(at: now) { return Count(big: "Today", unit: "") }
    let left = occurrence(at: now).timeIntervalSince(now)
    if mode == .sleeps {
      let s = sleeps(at: now)
      return Count(big: "\(s)", unit: s == 1 ? "sleep" : "sleeps")
    }
    if left < 86_400 {
      if left >= 3_600 {
        let h = Int(left / 3_600)
        return Count(big: "\(h)", unit: h == 1 ? "hour" : "hours")
      }
      return Count(big: "\(max(0, Int(left / 60)))", unit: "min")
    }
    let d = Int(left / 86_400)
    return Count(big: "\(d)", unit: d == 1 ? "day" : "days")
  }

  /// Share of the wait already behind you, 0 to 1.
  func progress(at now: Date) -> Double {
    let start = Date(timeIntervalSince1970: createdAt)
    let end = occurrence(at: now)
    let total = end.timeIntervalSince(start)
    guard total > 0 else { return 1 }
    return min(1, max(0, now.timeIntervalSince(start) / total))
  }

  func shortDate(at now: Date) -> String {
    let date = occurrence(at: now)
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US")
    f.setLocalizedDateFormatFromTemplate(
      calendar.component(.year, from: date) == calendar.component(.year, from: now)
        ? "EEEMMMd" : "EEEMMMdyyyy")
    return f.string(from: date)
  }

  // MARK: Look

  var ink: Color { Color(hex: text) }
  var hasPhoto: Bool { photo != nil }

  var gradientColors: [Color] { colors.map(Color.init(hex:)) }
}

extension Color {
  init(hex: String) {
    let value = UInt64(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
    self.init(
      red: Double((value >> 16) & 0xFF) / 255,
      green: Double((value >> 8) & 0xFF) / 255,
      blue: Double(value & 0xFF) / 255)
  }

  static let ink = Color(hex: "#1C1633")
  static let ground = Color(hex: "#F5F4FF")
  static let secondaryText = Color(hex: "#5E5878")
  static let scrim = Color(hex: "#120F22")
}
