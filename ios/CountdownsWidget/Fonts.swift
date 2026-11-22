import CoreText
import SwiftUI

/// The fonts the app bundles, by PostScript name. The widget bundles the
/// same files (see the target's Copy Bundle Resources and UIAppFonts).
/// Countdown fonts are Google fonts that arrive as files in the App Group,
/// registered at runtime.
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
  static func event(_ event: WidgetEvent, _ size: CGFloat) -> Font {
    if let file = event.fontFile, let name = RuntimeFonts.postScriptName(file) {
      return .custom(name, fixedSize: size)
    }
    // Default, and a Google font that hasn't downloaded yet.
    return .custom("BricolageGrotesque-36ptBold", fixedSize: size)
  }
}

/// Google fonts the app downloaded into the App Group (`widget/fonts`).
/// Registered for this process only, the first time a widget needs one.
enum RuntimeFonts {
  private static var names: [String: String] = [:]
  private static let lock = NSLock()

  /// The PostScript name to ask SwiftUI for, or nil if the file is missing
  /// or unreadable (the widget then uses Default).
  static func postScriptName(_ relative: String) -> String? {
    lock.lock()
    defer { lock.unlock() }
    if let name = names[relative] { return name }
    guard let url = SnapshotStore.folder?.appendingPathComponent(relative),
      FileManager.default.fileExists(atPath: url.path),
      let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL)
        as? [CTFontDescriptor],
      let first = descriptors.first,
      let name = CTFontDescriptorCopyAttribute(first, kCTFontNameAttribute) as? String
    else { return nil }
    var error: Unmanaged<CFError>?
    if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
      // Already registered by an earlier timeline, or a bundled font has
      // the same name: either way, use it if it resolves.
      guard UIFont(name: name, size: 12) != nil else { return nil }
    }
    names[relative] = name
    return name
  }
}
