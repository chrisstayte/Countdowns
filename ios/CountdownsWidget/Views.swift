import SwiftUI
import WidgetKit

// MARK: - Backgrounds

struct EventBackground: View {
  let event: WidgetEvent
  var wide = false

  var body: some View {
    if let image = SnapshotStore.image(wide ? event.photoWide : event.photo) {
      ZStack {
        Image(uiImage: image).resizable().scaledToFill()
        LinearGradient(
          colors: [
            Color.scrim.opacity(event.darken),
            Color.scrim.opacity(min(1, event.darken + 0.15)),
          ],
          startPoint: .top, endPoint: .bottom)
      }
    } else {
      fill
    }
  }

  @ViewBuilder private var fill: some View {
    let colors = event.gradientColors
    if colors.count < 2 {
      (colors.first ?? .ink)
    } else {
      switch event.direction {
      case "radial":
        RadialGradient(colors: colors, center: .center, startRadius: 0, endRadius: 180)
      case "sweep":
        AngularGradient(colors: colors + [colors[0]], center: .center)
      default:
        let (start, end) = points
        LinearGradient(colors: colors, startPoint: start, endPoint: end)
      }
    }
  }

  private var points: (UnitPoint, UnitPoint) {
    switch event.direction {
    case "down": return (.top, .bottom)
    case "up": return (.bottom, .top)
    case "right": return (.leading, .trailing)
    case "left": return (.trailing, .leading)
    case "diagonalUp": return (.bottomLeading, .topTrailing)
    default: return (.topLeading, .bottomTrailing)
    }
  }
}

struct EventIcon: View {
  let event: WidgetEvent
  let size: CGFloat

  var body: some View {
    if let image = SnapshotStore.image(event.icon) {
      Image(uiImage: image).resizable().frame(width: size, height: size)
        .accessibilityHidden(true)
    }
  }
}

private extension View {
  func onPhoto(_ event: WidgetEvent) -> some View {
    shadow(color: event.hasPhoto ? .black.opacity(0.35) : .clear, radius: 4, y: 1)
  }
}

// MARK: - Home screen

struct SmallView: View {
  let entry: CountdownEntry
  let event: WidgetEvent

  var body: some View {
    let count = event.count(at: entry.date, mode: entry.mode(for: event))
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top, spacing: 6) {
        Text(event.title)
          .font(WidgetFont.event(event.font, 17))
          .lineLimit(2)
          .minimumScaleFactor(0.8)
        Spacer(minLength: 0)
        EventIcon(event: event, size: 20)
      }
      Spacer(minLength: 0)
      HStack(alignment: .firstTextBaseline, spacing: 4) {
        Text(count.big).font(WidgetFont.numeral(50)).minimumScaleFactor(0.5)
        Text(count.unit).font(WidgetFont.ui(14, bold: true))
      }
      .lineLimit(1)
      Text(event.shortDate(at: entry.date)).font(WidgetFont.ui(12))
        .opacity(0.85)
    }
    .foregroundStyle(event.ink)
    .onPhoto(event)
  }
}

struct MediumView: View {
  let entry: CountdownEntry
  let event: WidgetEvent

  var body: some View {
    let count = event.count(at: entry.date, mode: entry.mode(for: event))
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 2) {
          Text(entry.pinned ? "COUNTDOWN" : "UP NEXT")
            .font(WidgetFont.ui(11, bold: true)).kerning(0.9)
          Text(event.title)
            .font(WidgetFont.event(event.font, 22))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        Spacer(minLength: 8)
        EventIcon(event: event, size: 22)
      }
      Spacer(minLength: 0)
      HStack(alignment: .bottom) {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
          Text(count.big).font(WidgetFont.numeral(60)).minimumScaleFactor(0.5)
          Text(count.unit).font(WidgetFont.ui(16, bold: true))
        }
        .lineLimit(1)
        Spacer(minLength: 8)
        VStack(alignment: .trailing, spacing: 6) {
          Text(event.shortDate(at: entry.date)).font(WidgetFont.ui(12))
          ProgressBar(value: event.progress(at: entry.date), ink: event.ink)
            .frame(width: 130, height: 8)
        }
      }
    }
    .foregroundStyle(event.ink)
    .onPhoto(event)
  }
}

struct ProgressBar: View {
  let value: Double
  let ink: Color

  var body: some View {
    GeometryReader { geo in
      ZStack(alignment: .leading) {
        Capsule().fill(ink.opacity(0.18))
        Capsule().fill(ink).frame(width: max(8, geo.size.width * value))
      }
    }
    .accessibilityLabel("\(Int(value * 100)) percent of the wait is behind you")
  }
}

struct LargeView: View {
  let entry: CountdownEntry

  var body: some View {
    VStack(spacing: 10) {
      if let lead = entry.lead {
        let count = lead.count(at: entry.date, mode: entry.mode(for: lead))
        HStack(alignment: .bottom) {
          VStack(alignment: .leading, spacing: 2) {
            Text(entry.pinned ? "COUNTDOWN" : "UP NEXT")
              .font(WidgetFont.ui(11, bold: true)).kerning(0.9)
            Text(lead.title).font(WidgetFont.event(lead.font, 20)).lineLimit(1)
          }
          Spacer(minLength: 8)
          HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(count.big).font(WidgetFont.numeral(48))
            Text(count.unit).font(WidgetFont.ui(14, bold: true))
          }
          .lineLimit(1)
          .minimumScaleFactor(0.6)
        }
        .foregroundStyle(lead.ink)
        .onPhoto(lead)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(EventBackground(event: lead, wide: true))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
      }
      ForEach(entry.events.dropFirst().prefix(4)) { event in
        ListRow(entry: entry, event: event)
      }
      Spacer(minLength: 0)
    }
  }
}

struct ListRow: View {
  let entry: CountdownEntry
  let event: WidgetEvent

  var body: some View {
    let count = event.count(at: entry.date, mode: entry.mode(for: event))
    HStack(spacing: 10) {
      ZStack {
        EventBackground(event: event)
        EventIcon(event: event, size: 18)
      }
      .frame(width: 34, height: 34)
      .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
      VStack(alignment: .leading, spacing: 0) {
        Text(event.title).font(WidgetFont.event(event.font, 15)).lineLimit(1)
        Text(event.shortDate(at: entry.date)).font(WidgetFont.ui(11))
          .foregroundStyle(Color.secondaryText)
      }
      Spacer(minLength: 6)
      HStack(alignment: .firstTextBaseline, spacing: 2) {
        Text(count.big).font(WidgetFont.numeral(22))
        Text(count.unit == "" ? "" : (entry.mode(for: event) == .sleeps ? " sl" : " d"))
          .font(WidgetFont.ui(12, bold: true)).foregroundStyle(Color.secondaryText)
      }
    }
    .foregroundStyle(Color.ink)
    .frame(height: 38)
  }
}

struct NoCountdownsView: View {
  var body: some View {
    VStack(spacing: 6) {
      Text("No countdowns yet").font(WidgetFont.numeral(17))
      Text("Add one in the app.").font(WidgetFont.ui(12))
        .foregroundStyle(Color.secondaryText)
    }
    .foregroundStyle(Color.ink)
    .multilineTextAlignment(.center)
  }
}

// MARK: - Lock screen (rendered in one tint by the system)

struct CircularView: View {
  let entry: CountdownEntry
  let event: WidgetEvent

  var body: some View {
    let count = event.count(at: entry.date, mode: entry.mode(for: event))
    Gauge(value: event.progress(at: entry.date)) {
      EmptyView()
    } currentValueLabel: {
      VStack(spacing: -2) {
        Text(count.big).font(WidgetFont.numeral(count.big.count > 3 ? 14 : 20))
          .minimumScaleFactor(0.5)
        Text(count.unit.uppercased()).font(WidgetFont.ui(8, bold: true))
      }
    }
    .gaugeStyle(.accessoryCircularCapacity)
    .widgetAccentable()
    .accessibilityLabel("\(event.title), \(count.big) \(count.unit)")
  }
}

struct RectangularView: View {
  let entry: CountdownEntry
  let event: WidgetEvent

  var body: some View {
    let count = event.count(at: entry.date, mode: entry.mode(for: event))
    VStack(alignment: .leading, spacing: 2) {
      Text(event.title).font(WidgetFont.ui(13, bold: true)).lineLimit(1)
      HStack(alignment: .firstTextBaseline, spacing: 4) {
        Text(count.big).font(WidgetFont.numeral(24)).widgetAccentable()
        Text(count.unit).font(WidgetFont.ui(13, bold: true))
      }
      ProgressView(value: event.progress(at: entry.date)).tint(.primary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct InlineView: View {
  let entry: CountdownEntry
  let event: WidgetEvent

  var body: some View {
    let count = event.count(at: entry.date, mode: entry.mode(for: event))
    if count.unit.isEmpty {
      Text("\(event.title) is today")
    } else {
      Text("\(Image(systemName: "timer")) \(event.title) in \(count.big) \(count.unit)")
    }
  }
}
