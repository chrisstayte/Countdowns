import CoreText
import SwiftUI
import UIKit

/// The fonts the app bundles, by PostScript name. The widget bundles the
/// same files (see the target's Copy Bundle Resources and UIAppFonts).
/// Downloaded event fonts are rasterized by EventTitle before WidgetKit
/// archives the view: the system renderer cannot read App Group font files.
enum WidgetFont {
  static func numeral(_ size: CGFloat) -> Font {
    .custom(
      size >= 60 ? "BricolageGrotesque-96ptExtraBold" : "BricolageGrotesque-36ptExtraBold",
      fixedSize: size)
  }

  static func ui(_ size: CGFloat, bold: Bool = false) -> Font {
    .custom(bold ? "Inter-Bold" : "Inter-SemiBold", fixedSize: size)
  }

  /// The event's own font, for titles.
  static func event(_ size: CGFloat) -> Font {
    // Default, and a Google font that hasn't downloaded yet.
    return .custom("BricolageGrotesque-36ptBold", fixedSize: size)
  }
}

/// A downloaded font can load in the extension while being unreadable by
/// the system renderer on a real phone. Archive the finished title image,
/// keeping the title accessible and all countdown numbers as live Text.
struct EventTitle: View {
  let event: WidgetEvent
  let size: CGFloat
  var lines = 1
  var minimumScale: CGFloat = 1
  var color: Color? = nil

  var body: some View {
    if let file = event.fontFile,
      let font = RuntimeFonts.font(file, size: size)
    {
      RasterEventTitle(text: event.title, font: font, color: UIColor(color ?? event.ink),
        lines: lines, minimumScale: minimumScale)
    } else {
      Text(event.title)
        .font(WidgetFont.event(size))
        .lineLimit(lines)
        .minimumScaleFactor(minimumScale)
    }
  }
}

struct RasterEventTitle: View {
  let text: String
  let font: UIFont
  let color: UIColor
  let lines: Int
  let minimumScale: CGFloat

  var body: some View {
    RasterTitleLayout(text: text, font: font, lines: lines, minimumScale: minimumScale) {
      GeometryReader { geometry in
        Image(uiImage: RasterTitle.image(
          text: text, font: font, color: color, size: geometry.size,
          lines: lines, minimumScale: minimumScale))
          .resizable()
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(text)
  }
}

/// Measure with the same font and width as the rasterizer, so titles wrap
/// and shrink within each widget's actual space, including on iPad.
private struct RasterTitleLayout: Layout {
  let text: String
  let font: UIFont
  let lines: Int
  let minimumScale: CGFloat

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    RasterTitle.metrics(
      text: text, font: font, width: proposal.width, lines: lines,
      minimumScale: minimumScale).size
  }

  func placeSubviews(
    in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
  ) {
    subviews.first?.place(at: bounds.origin, proposal: ProposedViewSize(bounds.size))
  }
}

enum RasterTitle {
  private static let images: NSCache<NSString, UIImage> = {
    let cache = NSCache<NSString, UIImage>()
    cache.totalCostLimit = 4 * 1024 * 1024
    return cache
  }()

  private static func attributes(
    _ font: UIFont, color: UIColor = .black
  ) -> [NSAttributedString.Key: Any] {
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineBreakMode = .byWordWrapping
    return [.font: font, .foregroundColor: color, .paragraphStyle: paragraph]
  }

  static func metrics(
    text: String, font: UIFont, width: CGFloat?, lines: Int, minimumScale: CGFloat
  ) -> (size: CGSize, font: UIFont) {
    let width = max(1, width ?? .greatestFiniteMagnitude)
    let lines = max(1, lines)
    func measure(_ font: UIFont) -> CGSize {
      (text as NSString).boundingRect(
        with: CGSize(width: lines == 1 ? .greatestFiniteMagnitude : width,
          height: .greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: attributes(font), context: nil).size
    }
    func fits(_ font: UIFont) -> Bool {
      let measured = measure(font)
      return measured.width <= width && measured.height <= font.lineHeight * CGFloat(lines) + 1
    }
    var fitted = font
    if !fits(font) {
      var low = min(1, max(0.1, minimumScale))
      var high: CGFloat = 1
      for _ in 0..<10 {
        let mid = (low + high) / 2
        if fits(font.withSize(font.pointSize * mid)) { low = mid } else { high = mid }
      }
      fitted = font.withSize(font.pointSize * low)
    }
    let measured = measure(fitted)
    return (CGSize(
      width: max(1, min(width, ceil(measured.width))),
      height: max(1, ceil(min(measured.height, fitted.lineHeight * CGFloat(lines))))), fitted)
  }

  static func image(
    text: String, font: UIFont, color: UIColor, size: CGSize, lines: Int, minimumScale: CGFloat
  ) -> UIImage {
    let size = CGSize(width: max(1, size.width), height: max(1, size.height))
    // Title/font edits get a new key; counts and dates never use this cache.
    let key = "\(text)|\(font.fontName)|\(font.pointSize)|\(color)|\(size)|\(lines)|\(minimumScale)" as NSString
    if let cached = images.object(forKey: key) { return cached }
    let fitted = metrics(
      text: text, font: font, width: size.width, lines: lines, minimumScale: minimumScale).font
    let format = UIGraphicsImageRendererFormat()
    format.scale = 3
    format.preferredRange = .standard
    let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
      (text as NSString).draw(
        with: CGRect(origin: .zero, size: size),
        options: [.usesLineFragmentOrigin, .usesFontLeading, .truncatesLastVisibleLine],
        attributes: attributes(fitted, color: color), context: nil)
    }
    images.setObject(image, forKey: key,
      cost: (image.cgImage?.bytesPerRow ?? 0) * (image.cgImage?.height ?? 0))
    return image
  }
}

/// Load downloaded fonts only for local rasterization. Avoid registering
/// them by name: a downloaded Inter or Bricolage must not replace a bundled
/// font that the rest of the widget still uses in archived Text views.
enum RuntimeFonts {
  private static var fonts: [URL: CGFont] = [:]
  private static let lock = NSLock()

  static func font(_ relative: String, size: CGFloat) -> UIFont? {
    guard let url = SnapshotStore.folder?.appendingPathComponent(relative) else { return nil }
    return font(at: url, size: size)
  }

  /// Nil for missing or damaged files, so the title uses Default.
  static func font(at url: URL, size: CGFloat) -> UIFont? {
    lock.lock()
    defer { lock.unlock() }
    let graphicsFont: CGFont
    if let cached = fonts[url] {
      graphicsFont = cached
    } else {
      guard let data = try? Data(contentsOf: url),
        let provider = CGDataProvider(data: data as CFData),
        let loaded = CGFont(provider)
      else { return nil }
      fonts[url] = loaded
      graphicsFont = loaded
    }
    return CTFontCreateWithGraphicsFont(graphicsFont, size, nil, nil) as UIFont
  }
}
