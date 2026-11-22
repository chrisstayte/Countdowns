import SwiftUI

/// The fonts the app bundles, by PostScript name. The widget bundles the
/// same files (see the target's Copy Bundle Resources and UIAppFonts).
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
  static func event(_ family: String, _ size: CGFloat) -> Font {
    let name: String
    switch family {
    case "Roboto": name = "Roboto-Bold"
    case "GoodTimes": name = "GoodTimesRg-Regular"
    case "LibreBaskerville": name = "LibreBaskerville-Bold"
    case "LuxuriousRoman": name = "LuxuriousRoman-Regular"
    case "ComicNeue": name = "ComicNeue-Bold"
    case "DiarioDeAndy": name = "DIARIO_DE_ANDY"
    case "Sunnyspells": name = "SunnySpells-Regular"
    case "CarnivaleeFreakshow": name = "CarnivaleeFreakshow"
    case "Starjedi": name = "StarJedi"
    case "NewWaltDisney": name = "NewWaltDisneyUI"
    default: name = "BricolageGrotesque-36ptBold"
    }
    return .custom(name, fixedSize: size)
  }
}
