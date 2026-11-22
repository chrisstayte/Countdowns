import Foundation
import SwiftUI
import UIKit

let appGroup = "group.com.chrisstayte.countdowns"

/// One countdown as the Flutter app wrote it to `widget/snapshot.json`.
struct WidgetEvent: Codable, Identifiable, Hashable {
  let id: Int
  /// countdowns://event/<id>: what a tap on this countdown opens.
  let link: String?
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
  /// The full-screen crop, for the large widget's single-countdown hero.
  let photoFull: String?
  let darken: Double
  let createdAt: TimeInterval
  /// False for drawn art (patterns, textures, illustrations): no scrim and
  /// no text shadow. Missing in older snapshots, which only had photos.
  var scrim: Bool? = nil
  /// A Google font's file, relative to the widget folder, for `font`.
  /// Nil for bundled fonts, and until the app has downloaded it.
  var fontFile: String? = nil
  /// Since events count up from `target`. Missing in older snapshots.
  var since: Bool? = nil
  /// Since only: milestone times (the last one passed, or the start, then
  /// the ones ahead), for the progress bar.
  var milestones: [TimeInterval]? = nil
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

  var isSince: Bool { since == true }

  /// The next time it happens on or after `now` (yearly events roll over).
  /// The start, for Since.
  func occurrence(at now: Date) -> Date {
    var date = Date(timeIntervalSince1970: target)
    guard yearly, !isSince else { return date }
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

  /// Since events keep counting, so they're never done.
  func isDone(at now: Date) -> Bool {
    !isSince && !yearly && passed(occurrence(at: now), at: now)
  }

  /// What gets counted: now to the occurrence, or the start to now.
  func span(at now: Date) -> (from: Date, to: Date) {
    isSince ? (occurrence(at: now), now) : (now, occurrence(at: now))
  }

  func sleeps(at now: Date) -> Int {
    let (start, end) = span(at: now)
    let from = calendar.startOfDay(for: start)
    let to = calendar.startOfDay(for: end)
    return max(0, calendar.dateComponents([.day], from: from, to: to).day ?? 0)
  }

  func count(at now: Date, mode: CountMode) -> Count {
    if isDone(at: now) { return Count(big: "0", unit: "days") }
    if isToday(at: now) { return Count(big: "Today", unit: "") }
    let (from, to) = span(at: now)
    let left = to.timeIntervalSince(from)
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

  /// Share of the wait already behind you, 0 to 1. For Since, the way
  /// from the last milestone to the next.
  func progress(at now: Date) -> Double {
    if isSince {
      let t = now.timeIntervalSince1970
      let marks = milestones ?? []
      guard let next = marks.first(where: { $0 > t }) else { return 1 }
      let last = marks.last(where: { $0 <= t }) ?? target
      guard next > last else { return 1 }
      return min(1, max(0, (t - last) / (next - last)))
    }
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
    return isSince ? "Since \(f.string(from: date))" : f.string(from: date)
  }

  /// The small heading over a featured countdown.
  func header(pinned: Bool) -> String {
    isSince ? "SINCE" : pinned ? "COUNTDOWN" : "UP NEXT"
  }

  // MARK: Look

  var url: URL? { link.flatMap(URL.init(string:)) }

  var ink: Color { Color(hex: text) }
  var hasPhoto: Bool { photo != nil }
  /// White text on a darkened photo gets a soft shadow; drawn art doesn't.
  var shadowed: Bool { hasPhoto && scrim != false }

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

  // The app's "Highlighter" palette.
  static let ink = Color(hex: "#2E2A3A")
  static let ground = Color(hex: "#FBF9F3")  // Paper
  static let secondaryText = Color(hex: "#6B6677")  // Pencil
  static let scrim = Color(hex: "#120F22")
}
