// Flatten exports to sRGB RGB PNGs (no alpha channel), then make launcher PNGs.
// swift tool/store-assets/opaque.swift store-assets/v3
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "store-assets/v3")
let fm = FileManager.default
let space = CGColorSpace(name: CGColorSpace.sRGB)!

func read(_ url: URL) throws -> CGImage {
  guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
  else { throw NSError(domain: "StoreAssets", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot read \(url.path)"]) }
  return image
}

func save(_ image: CGImage, to url: URL, width: Int? = nil, alpha: Bool = false) throws {
  let w = width ?? image.width
  let h = width == nil ? image.height : Int((Double(image.height) * Double(w) / Double(image.width)).rounded())
  let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
    space: space, bitmapInfo: alpha ? CGImageAlphaInfo.premultipliedLast.rawValue : CGImageAlphaInfo.noneSkipLast.rawValue)!
  ctx.setFillColor(CGColor(gray: 1, alpha: 1))
  ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
  ctx.interpolationQuality = .high
  ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
  try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
  guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
  else { throw NSError(domain: "StoreAssets", code: 2) }
  CGImageDestinationAddImage(destination, ctx.makeImage()!, nil)
  guard CGImageDestinationFinalize(destination) else { throw NSError(domain: "StoreAssets", code: 3) }
}

var count = 0
let files = fm.enumerator(at: root, includingPropertiesForKeys: nil)!.allObjects.compactMap { $0 as? URL }
for url in files where url.pathExtension == "png" {
  try save(read(url), to: url)
  count += 1
}
let icon = try read(root.appendingPathComponent("brand/icon-1024.png"))
try save(icon, to: root.appendingPathComponent("campaign/google-play/app-icon.png"), width: 512, alpha: true)
for (density, size) in [("mdpi",48),("hdpi",72),("xhdpi",96),("xxhdpi",144),("xxxhdpi",192)] {
  try save(icon, to: URL(fileURLWithPath: "android/app/src/main/res/mipmap-\(density)/countdowns.png"), width: size)
}
print("Normalized \(count) store PNGs to opaque sRGB; exported Play icon and 5 Android legacy launcher sizes.")
