import SwiftUI
import WidgetKit

@main
struct CountdownsWidgets: WidgetBundle {
  var body: some Widget {
    HomeCountdownWidget()
    LockCountdownWidget()
  }
}

struct HomeCountdownWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: "CountdownHome", intent: CountdownWidgetIntent.self,
      provider: CountdownProvider()
    ) { entry in
      HomeEntryView(entry: entry)
    }
    .configurationDisplayName("Countdown")
    .description("Up next, or one countdown you pick.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    .contentMarginsDisabled()
  }
}

struct HomeEntryView: View {
  @Environment(\.widgetFamily) private var family
  let entry: CountdownEntry

  var body: some View {
    Group {
      if let lead = entry.lead {
        switch family {
        case .systemLarge:
          LargeView(entry: entry)
            .padding(18)
            .containerBackground(for: .widget) { Color.ground }
        case .systemMedium:
          MediumView(entry: entry, event: lead)
            .padding(.horizontal, 18).padding(.vertical, 16)
            .containerBackground(for: .widget) { EventBackground(event: lead, wide: true) }
        default:
          SmallView(entry: entry, event: lead)
            .padding(16)
            .containerBackground(for: .widget) { EventBackground(event: lead) }
        }
      } else {
        NoCountdownsView()
          .containerBackground(for: .widget) { Color.ground }
      }
    }
  }
}

struct LockCountdownWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: "CountdownLock", intent: CountdownWidgetIntent.self,
      provider: CountdownProvider()
    ) { entry in
      LockEntryView(entry: entry)
        .containerBackground(for: .widget) { Color.clear }
    }
    .configurationDisplayName("Countdown")
    .description("Up next, or one countdown you pick.")
    .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
  }
}

struct LockEntryView: View {
  @Environment(\.widgetFamily) private var family
  let entry: CountdownEntry

  var body: some View {
    if let lead = entry.lead {
      switch family {
      case .accessoryCircular: CircularView(entry: entry, event: lead)
      case .accessoryInline: InlineView(entry: entry, event: lead)
      default: RectangularView(entry: entry, event: lead)
      }
    } else {
      Text("No countdowns")
    }
  }
}
