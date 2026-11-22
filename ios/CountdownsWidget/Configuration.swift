import AppIntents
import WidgetKit

/// A countdown the person can pin a widget to.
struct CountdownEntity: AppEntity {
  let id: Int
  let title: String

  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Up next"
  static var defaultQuery = CountdownQuery()

  var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(title)") }
}

struct CountdownQuery: EntityQuery {
  func entities(for identifiers: [Int]) async throws -> [CountdownEntity] {
    SnapshotStore.load()
      .filter { identifiers.contains($0.id) }
      .map { CountdownEntity(id: $0.id, title: $0.title) }
  }

  func suggestedEntities() async throws -> [CountdownEntity] {
    SnapshotStore.load().map { CountdownEntity(id: $0.id, title: $0.title) }
  }
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

/// Widget settings: follow Up next (no countdown picked) or pin one, and
/// count in days or sleeps.
struct CountdownWidgetIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Countdown"
  static var description = IntentDescription("Follow Up next or pin one countdown.")

  @Parameter(title: "Show", description: "Leave it on Up next, or pin one countdown.")
  var countdown: CountdownEntity?

  @Parameter(title: "Count in", default: .event)
  var countIn: CountIn
}
