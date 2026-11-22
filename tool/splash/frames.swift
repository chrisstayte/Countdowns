// Pulls evenly spaced frames from a screen recording, to check a launch
// for flashes:  swift tool/splash/frames.swift <video> <outdir> [step]
import AVFoundation
import AppKit

let args = CommandLine.arguments
let asset = AVURLAsset(url: URL(fileURLWithPath: args[1]))
let out = URL(fileURLWithPath: args[2], isDirectory: true)
let step = args.count > 3 ? Double(args[3])! : 0.1
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
let gen = AVAssetImageGenerator(asset: asset)
gen.requestedTimeToleranceBefore = .zero
gen.requestedTimeToleranceAfter = .zero
gen.maximumSize = CGSize(width: 300, height: 700)
let duration = CMTimeGetSeconds(asset.duration)
var t = 0.0
var i = 0
while t < duration {
  if let img = try? gen.copyCGImage(at: CMTime(seconds: t, preferredTimescale: 600), actualTime: nil) {
    let rep = NSBitmapImageRep(cgImage: img)
    let name = String(format: "%03d-%.2fs.png", i, t)
    try? rep.representation(using: .png, properties: [:])?.write(to: out.appendingPathComponent(name))
  }
  t += step
  i += 1
}
print("frames:", i, "duration:", duration)

// Contact sheet of every frame, 10 per row, for a quick look.
let files = (try? FileManager.default.contentsOfDirectory(atPath: out.path))?
  .filter { $0.hasSuffix(".png") && $0 != "sheet.png" }.sorted() ?? []
let cellW = 120, cellH = 270, cols = 10
let rows = (files.count + cols - 1) / cols
let sheet = NSImage(size: NSSize(width: cols * cellW, height: rows * (cellH + 16)))
sheet.lockFocus()
NSColor.darkGray.setFill()
NSRect(x: 0, y: 0, width: sheet.size.width, height: sheet.size.height).fill()
for (n, f) in files.enumerated() {
  guard let img = NSImage(contentsOf: out.appendingPathComponent(f)) else { continue }
  let x = (n % cols) * cellW
  let y = Int(sheet.size.height) - (n / cols + 1) * (cellH + 16)
  img.draw(in: NSRect(x: x + 2, y: y + 16, width: cellW - 4, height: cellH))
  (f.split(separator: "-").last.map(String.init) ?? f).replacingOccurrences(of: ".png", with: "")
    .draw(at: NSPoint(x: x + 4, y: y + 1), withAttributes: [.foregroundColor: NSColor.white, .font: NSFont.systemFont(ofSize: 11)])
}
sheet.unlockFocus()
if let tiff = sheet.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) {
  try? rep.representation(using: .png, properties: [:])?.write(to: out.appendingPathComponent("sheet.png"))
}
