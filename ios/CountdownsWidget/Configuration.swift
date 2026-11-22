import AppIntents
import WidgetKit

/// A countdown the person can pin a widget to.
struct CountdownEntity: AppEntity {
  let id: Int
  let title: String

  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Up next"
  static var defaultQuery = CountdownQuery()

  /// Database IDs are positive. This choice remains resolvable even when
  /// there are no events, and lets people return to the automatic selection.
  static let upNext = CountdownEntity(id: 0, title: "Up next")

  var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(title)") }
}

struct CountdownQuery: EntityQuery {
  func entities(for identifiers: [Int]) async throws -> [CountdownEntity] {
    let events = SnapshotStore.load()
    return identifiers.compactMap { id in
      if id == CountdownEntity.upNext.id { return .upNext }
      return events.first(where: { $0.id == id })
        .map { CountdownEntity(id: $0.id, title: $0.title) }
    }
  }

  func suggestedEntities() async throws -> [CountdownEntity] {
    [.upNext] + SnapshotStore.load().map { CountdownEntity(id: $0.id, title: $0.title) }
  }

  func defaultResult() async -> CountdownEntity? { .upNext }
}

enum CountIn: String, AppEnum {
  case event, days, sleeps

  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Count in"
  static var caseDisplayRepresentations: [CountIn: DisplayRepresentation] = [
    .event: "As set in the app",
    .days: "Days",
    .sleeps: "Sleeps",
  ]
}

/// The large widget's layout.
enum LargeLayoutChoice: String, AppEnum {
  case list, single

  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Layout"
  static var caseDisplayRepresentations: [LargeLayoutChoice: DisplayRepresentation] = [
    .list: "List",
    .single: "One countdown",
  ]
}

/// Widget settings: follow Up next (no countdown picked) or pin one, and
/// count in days or sleeps.
struct CountdownWidgetIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Countdown"
  static var description = IntentDescription("Follow Up next or pin one countdown.")

  @Parameter(title: "Show", description: "Leave it on Up next, or pin one countdown.")
  var countdown: CountdownEntity?

  @Parameter(title: "Count in", default: .event)
  var countIn: CountIn

  /// List: Up next, or a hero when only one is active. One countdown:
  /// always a hero (the pinned one, else the next). Large size only.
  @Parameter(title: "Layout", default: .list)
  var layout: LargeLayoutChoice

  // Show Layout only when editing a large widget.
  static var parameterSummary: some ParameterSummary {
    When(widgetFamily: .equalTo, .systemLarge) {
      Summary {
        \.$countdown
        \.$countIn
        \.$layout
      }
    } otherwise: {
      Summary {
        \.$countdown
        \.$countIn
      }
    }
  }
}
