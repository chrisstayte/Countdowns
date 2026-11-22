import WidgetKit

struct CountdownEntry: TimelineEntry {
  let date: Date
  /// The chosen countdown first, then the rest of Up next (for Large).
  let events: [WidgetEvent]
  let pinned: Bool
  let countIn: CountIn

  var lead: WidgetEvent? { events.first }

  func mode(for event: WidgetEvent) -> CountMode {
    switch countIn {
    case .days: return .days
    case .sleeps: return .sleeps
    case .event: return event.unit == "sleeps" ? .sleeps : .days
    }
  }
}

struct CountdownProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> CountdownEntry {
    CountdownEntry(date: .now, events: [.sample], pinned: false, countIn: .event)
  }

  func snapshot(for configuration: CountdownWidgetIntent, in context: Context) async
    -> CountdownEntry
  {
    let entry = makeEntry(configuration, at: .now)
    return entry.events.isEmpty && context.isPreview
      ? placeholder(in: context) : entry
  }

  func timeline(for configuration: CountdownWidgetIntent, in context: Context) async
    -> Timeline<CountdownEntry>
  {
    // Numbers change at most every minute on the last hour, otherwise
    // hourly. One entry every 15 minutes for 12 hours covers both well.
    let now = Date.now
    let entries = (0..<48).map { step in
      makeEntry(configuration, at: now.addingTimeInterval(Double(step) * 900))
    }
    return Timeline(entries: entries, policy: .after(now.addingTimeInterval(12 * 3600)))
  }

  private func makeEntry(_ configuration: CountdownWidgetIntent, at date: Date)
    -> CountdownEntry
  {
    let upcoming = SnapshotStore.load()
      .filter { !$0.isDone(at: date) }
      .sorted { $0.occurrence(at: date) < $1.occurrence(at: date) }
    var events = upcoming
    var pinned = false
    if let id = configuration.countdown?.id,
      let chosen = upcoming.first(where: { $0.id == id })
    {
      events = [chosen] + upcoming.filter { $0.id != id }
      pinned = true
    }
    return CountdownEntry(
      date: date, events: events, pinned: pinned, countIn: configuration.countIn)
  }
}

extension WidgetEvent {
  static let sample = WidgetEvent(
    id: 0, link: nil, title: "Thanksgiving",
    target: Date.now.addingTimeInterval(4 * 86_400 + 3_600).timeIntervalSince1970,
    allDay: true, yearly: false, unit: "days", font: "Default", text: "#1C1633",
    colors: ["#FE7228"], direction: "diagonalDown", icon: nil, photo: nil,
    photoWide: nil, photoFull: nil, darken: 0.35,
    createdAt: Date.now.addingTimeInterval(-10 * 86_400).timeIntervalSince1970)
}
