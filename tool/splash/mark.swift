// Draws the default "Highlighter" app icon mark (ink double triangle with
// two highlighter swipes) as vectors, from the same coordinates as the
// Android VectorDrawables in android/app/src/main/res/drawable/splash_*.xml.
//
//   swift tool/splash/mark.swift mark.pdf [preview.png]
//   cd ios/Runner/Assets.xcassets/SplashMark.imageset
//   sips -s format png -z 121 112 mark.pdf --out SplashMark.png
//   sips -s format png -z 242 224 mark.pdf --out SplashMark@2x.png
//   sips -s format png -z 363 336 mark.pdf --out SplashMark@3x.png
//
// The iOS launch screen uses those PNGs at the mark's on-screen size,
// 112 x 121 pt. The optional preview is for comparing against the app icon.
// Coordinates are in the 1024-point app icon space; the PDF is cropped to
// the mark (x 140...885, y 110...915).
//
// Testing a changed launch screen on a simulator: iOS keeps rendering the
// old one (here, Paper without the mark) until the simulator reboots, even
// after reinstalling and clearing the app's SplashBoard folder.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let crop = CGRect(x: 140, y: 110, width: 745, height: 805)
let points = CGSize(width: 112, height: 121)

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
  CGColor(
    srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
    blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

let ink = color(0x2E2A3A)
let shadowInk = color(0x2E2A3A, 0.55)
let highlighter = color(0xFFE36E)

func path(_ points: [(CGFloat, CGFloat)], closed: Bool = false) -> CGPath {
  let p = CGMutablePath()
  p.move(to: CGPoint(x: points[0].0, y: points[0].1))
  for pt in points.dropFirst() { p.addLine(to: CGPoint(x: pt.0, y: pt.1)) }
  if closed { p.closeSubpath() }
  return p
}

// Shared with the VectorDrawables. Keep the two in step.
let swipes = [path([(195, 184), (830, 164)]), path([(205, 860), (820, 840)])]
let shadows = [
  path([(249, 163), (824, 163), (534, 665)], closed: true),
  path([(594, 440), (534, 335), (249, 840), (824, 840), (664, 568)]),
]
let strokes = [
  path([(225, 173), (800, 173), (510, 675)], closed: true),
  path([(570, 450), (510, 345), (225, 850), (800, 850), (640, 578)]),
]

func draw(_ ctx: CGContext) {
  ctx.setLineCap(.round)
  ctx.setLineJoin(.round)
  for (paths, colour, width) in [
    (swipes, highlighter, CGFloat(92)), (shadows, shadowInk, 18), (strokes, ink, 26),
  ] {
    ctx.setStrokeColor(colour)
    ctx.setLineWidth(width)
    for p in paths {
      ctx.addPath(p)
      ctx.strokePath()
    }
  }
}

let args = CommandLine.arguments
guard args.count >= 2 else {
  print("usage: swift mark.swift <out.pdf> [preview.png]")
  exit(1)
}

// PDF, cropped to the mark. PDF space is bottom-up, so flip.
var box = CGRect(origin: .zero, size: points)
let pdf = CGContext(URL(fileURLWithPath: args[1]) as CFURL, mediaBox: &box, nil)!
pdf.beginPDFPage(nil)
pdf.translateBy(x: 0, y: points.height)
pdf.scaleBy(x: points.width / crop.width, y: -points.height / crop.height)
pdf.translateBy(x: -crop.minX, y: -crop.minY)
draw(pdf)
pdf.endPDFPage()
pdf.closePDF()

if args.count >= 3 {
  // Full 1024 preview on white, top-down like the app icon PNG.
  let ctx = CGContext(
    data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  ctx.setFillColor(color(0xFFFFFF))
  ctx.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
  ctx.translateBy(x: 0, y: 1024)
  ctx.scaleBy(x: 1, y: -1)
  draw(ctx)
  let dest = CGImageDestinationCreateWithURL(
    URL(fileURLWithPath: args[2]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
  CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
  CGImageDestinationFinalize(dest)
}
