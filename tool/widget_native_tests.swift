import CoreText
import SwiftUI
import UIKit

@main
struct WidgetNativeTests {
  @MainActor static func main() async throws {
    let root = URL(fileURLWithPath: CommandLine.arguments[1])
    let output = URL(fileURLWithPath: CommandLine.arguments[2])
    // Load a font from a writable directory, like an installed Google
    // font, without registering it or relying on UIAppFonts.
    let downloaded = output.appendingPathComponent("downloaded.ttf")
    try FileManager.default.copyItem(
      at: root.appendingPathComponent("fonts/Inter-700.ttf"), to: downloaded)
    let font = RuntimeFonts.font(at: downloaded, size: 22)!
    precondition(font.fontName == "Inter-Bold")
    precondition(RuntimeFonts.font(at: output.appendingPathComponent("missing.ttf"), size: 22) == nil)
    let damaged = output.appendingPathComponent("damaged.ttf")
    try Data("invalid font".utf8).write(to: damaged)
    precondition(RuntimeFonts.font(at: damaged, size: 22) == nil)

    func title(_ text: String, font: UIFont = font, color: UIColor = .black,
      width: CGFloat = 250, lines: Int = 1
    ) -> UIImage {
      let metrics = RasterTitle.metrics(
        text: text, font: font, width: width, lines: lines, minimumScale: 0.7)
      precondition(metrics.size.width <= width && metrics.size.height > 0)
      return RasterTitle.image(
        text: text, font: font, color: color, size: metrics.size,
        lines: lines, minimumScale: 0.7)
    }

    let original = title("Japan trip")
    let originalData = original.pngData()!
    precondition(original === title("Japan trip"), "Unchanged titles should reuse their image")
    precondition(originalData != title("Birthday").pngData(), "Title edits must invalidate the image")
    precondition(originalData != title("Japan trip", font: .italicSystemFont(ofSize: 22)).pngData(),
      "Font edits must invalidate the image")
    precondition(originalData != title("Japan trip", color: .white).pngData(),
      "Text color edits must invalidate the image")
    precondition(originalData != title("Japan trip", width: 60).pngData(),
      "Width changes must produce a fitted image")

    let longTitle = "A long countdown title for our next family holiday"
    let oneLine = RasterTitle.metrics(
      text: longTitle, font: font, width: 140, lines: 1, minimumScale: 0.7)
    let twoLines = RasterTitle.metrics(
      text: longTitle, font: font, width: 140, lines: 2, minimumScale: 0.7)
    precondition(oneLine.font.pointSize >= 22 * 0.7)
    precondition(oneLine.size.height <= ceil(oneLine.font.lineHeight))
    precondition(twoLines.size.height > oneLine.size.height)
    precondition(twoLines.size.height <= ceil(twoLines.font.lineHeight * 2))
    try title(longTitle, width: 140, lines: 2).pngData()!
      .write(to: output.appendingPathComponent("long-title.png"))
    try originalData.write(to: output.appendingPathComponent("custom-title.png"))
    // Exercise the SwiftUI layout too: GeometryReader must receive the
    // measured title height instead of expanding to fill the widget.
    let preview = VStack(alignment: .leading, spacing: 16) {
      RasterEventTitle(text: "Japan trip", font: font, color: .black,
        lines: 1, minimumScale: 0.7)
      RasterEventTitle(text: longTitle, font: font, color: .black,
        lines: 2, minimumScale: 0.7)
      RasterEventTitle(text: "日本への旅行 ✈️", font: font, color: .black,
        lines: 2, minimumScale: 0.7)
    }
    .frame(width: 140, alignment: .leading)
    .padding(16)
    .background(.white)
    let renderer = ImageRenderer(content: preview)
    renderer.scale = 3
    let rendered = renderer.uiImage!
    precondition(rendered.size.height < 220, "Titles must keep their intrinsic height")
    try rendered.pngData()!.write(to: output.appendingPathComponent("title-layout.png"))
    // Includes non-Latin glyph fallback, emoji, and an empty title.
    for text in ["日本への旅行 ✈️", "🎂 Birthday", "", "Supercalifragilisticexpialidocious"] {
      precondition(title(text, width: 140, lines: 2).pngData() != nil)
    }

    let query = CountdownQuery()
    let automatic = await query.defaultResult()
    precondition(automatic?.id == CountdownEntity.upNext.id)
    let resolved = try await query.entities(for: [CountdownEntity.upNext.id])
    precondition(resolved.first?.title == "Up next", "Automatic selection must always resolve")
    let suggestions = try await query.suggestedEntities()
    precondition(suggestions.first?.id == CountdownEntity.upNext.id)

    // The rendered title is independent of time. Counts continue to use
    // each timeline entry's date, including after leaving the app for a week.
    let now = Date(timeIntervalSince1970: 1_795_363_200)
    let event = WidgetEvent(
      id: 1, link: nil, title: "Japan trip",
      target: now.addingTimeInterval(20 * 86_400).timeIntervalSince1970,
      allDay: false, yearly: false, unit: "days", font: "Inter", text: "#000000",
      colors: ["#FE7228"], direction: "down", icon: nil, photo: nil,
      photoWide: nil, photoFull: nil, darken: 0.35,
      createdAt: now.timeIntervalSince1970)
    precondition(event.count(at: now, mode: .days).big == "20")
    precondition(event.count(at: now.addingTimeInterval(7 * 86_400), mode: .days).big == "13")
    precondition(original === title(event.title))
    print("Native widget regressions passed. Rendered titles: \(output.path)")
  }
}
