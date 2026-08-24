import AppKit
import Foundation

// Matches StatusArtwork.ring() in main.swift — solid pie wedge, not a donut ring.
private func pieWedge(in bounds: NSRect, percent: Double, fill: NSColor, track: NSColor) {
  let center = NSPoint(x: bounds.midX, y: bounds.midY)
  let radius = min(bounds.width, bounds.height) / 2

  let trackPath = NSBezierPath(ovalIn: bounds)
  track.setFill()
  trackPath.fill()

  let clamped = min(max(percent, 0), 100) / 100
  guard clamped > 0 else { return }

  fill.setFill()
  if clamped >= 1 {
    trackPath.fill()
    return
  }

  let start: CGFloat = 90
  let end = start - (360 * CGFloat(clamped))
  let wedge = NSBezierPath()
  wedge.move(to: center)
  wedge.line(to: pointOnCircle(center: center, radius: radius, degrees: start))
  wedge.appendArc(
    withCenter: center,
    radius: radius,
    startAngle: start,
    endAngle: end,
    clockwise: true
  )
  wedge.close()
  wedge.fill()
}

private func pointOnCircle(center: NSPoint, radius: CGFloat, degrees: CGFloat) -> NSPoint {
  let radians = degrees * .pi / 180
  return NSPoint(x: center.x + radius * cos(radians), y: center.y + radius * sin(radians))
}

private func savePNG(_ image: NSImage, to url: URL, size: NSSize) throws {
  guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size.width),
    pixelsHigh: Int(size.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
  ) else {
    throw NSError(domain: "assets", code: 1)
  }
  rep.size = size

  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
  image.draw(
    in: NSRect(origin: .zero, size: size),
    from: NSRect(origin: .zero, size: image.size),
    operation: .copy,
    fraction: 1
  )
  NSGraphicsContext.restoreGraphicsState()

  guard let data = rep.representation(using: .png, properties: [:]) else {
    throw NSError(domain: "assets", code: 2)
  }
  try data.write(to: url)
}

private func renderIcon() -> NSImage {
  let side: CGFloat = 1024
  let image = NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
    let corner = side * 0.22
    let bg = NSBezierPath(roundedRect: rect.insetBy(dx: side * 0.08, dy: side * 0.08), xRadius: corner, yRadius: corner)
    NSColor(calibratedRed: 0.11, green: 0.12, blue: 0.14, alpha: 1).setFill()
    bg.fill()

    let pieRect = rect.insetBy(dx: side * 0.28, dy: side * 0.28)
    pieWedge(
      in: pieRect,
      percent: 71,
      fill: NSColor(calibratedRed: 0.22, green: 0.55, blue: 0.98, alpha: 1),
      track: NSColor(calibratedWhite: 0.28, alpha: 1)
    )
    return true
  }
  return image
}

private func drawMenuPanel(in rect: NSRect) {
  let panel = NSBezierPath(roundedRect: rect, xRadius: 10, yRadius: 10)
  NSColor(calibratedWhite: 0.16, alpha: 0.96).setFill()
  panel.fill()
  NSColor(calibratedWhite: 0.28, alpha: 0.35).setStroke()
  panel.lineWidth = 1
  panel.stroke()

  let muted = NSColor(calibratedWhite: 0.55, alpha: 1)
  let text = NSColor(calibratedWhite: 0.92, alpha: 1)
  let accent = NSColor(calibratedRed: 0.35, green: 0.62, blue: 1, alpha: 1)

  func line(_ string: String, y: CGFloat, font: NSFont, color: NSColor) {
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
    (string as NSString).draw(at: NSPoint(x: rect.minX + 16, y: y), withAttributes: attrs)
  }

  let body = NSFont.systemFont(ofSize: 13, weight: .regular)
  let bodyMedium = NSFont.systemFont(ofSize: 13, weight: .medium)
  let small = NSFont.systemFont(ofSize: 12, weight: .regular)

  var y = rect.maxY - 28
  line("Included limit reached", y: y, font: bodyMedium, color: muted)
  y -= 24
  line("Included: $20.00 / $20.00 · exhausted", y: y, font: body, color: text)
  y -= 22
  line("Auto 68% · API 100% · Total 71%", y: y, font: body, color: text)
  y -= 22
  line("On-demand: off", y: y, font: body, color: text)
  y -= 14
  NSColor(calibratedWhite: 0.32, alpha: 1).setFill()
  NSRect(x: rect.minX + 12, y: y, width: rect.width - 24, height: 1).fill()
  y -= 18
  line("pro · resets Sep 17 (23d)", y: y, font: small, color: muted)
  y -= 14
  NSColor(calibratedWhite: 0.32, alpha: 1).setFill()
  NSRect(x: rect.minX + 12, y: y, width: rect.width - 24, height: 1).fill()
  y -= 22
  line("Refresh", y: y, font: body, color: text)
  y -= 22
  line("Open Dashboard", y: y, font: body, color: accent)
  y -= 22
  line("Quit", y: y, font: body, color: text)
}

private func renderHero() -> NSImage {
  let menuW: CGFloat = 300
  let menuH: CGFloat = 248
  let barHeight: CGFloat = 44
  let gap: CGFloat = 8
  let padX: CGFloat = 40
  let padTop: CGFloat = 24
  let padBottom: CGFloat = 28

  let width = menuW + padX * 2
  let height = padTop + barHeight + gap + menuH + padBottom

  let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { rect in
    let gradient = NSGradient(
      colors: [
        NSColor(calibratedRed: 0.07, green: 0.08, blue: 0.11, alpha: 1),
        NSColor(calibratedRed: 0.12, green: 0.13, blue: 0.17, alpha: 1),
      ]
    )!
    gradient.draw(in: rect, angle: 90)

    let barRect = NSRect(
      x: padX - 12,
      y: rect.maxY - padTop - barHeight,
      width: menuW + 24,
      height: barHeight
    )
    NSColor(calibratedWhite: 0.08, alpha: 0.85).setFill()
    NSBezierPath(roundedRect: barRect, xRadius: 8, yRadius: 8).fill()

    let iconSize: CGFloat = 18
    let iconX = width / 2 - iconSize / 2
    let iconY = barRect.minY + (barHeight - iconSize) / 2
    pieWedge(
      in: NSRect(x: iconX, y: iconY, width: iconSize, height: iconSize),
      percent: 71,
      fill: NSColor(calibratedWhite: 0.95, alpha: 1),
      track: NSColor(calibratedWhite: 0.35, alpha: 1)
    )

    let menuRect = NSRect(
      x: padX,
      y: barRect.minY - gap - menuH,
      width: menuW,
      height: menuH
    )
    drawMenuPanel(in: menuRect)
    return true
  }
  return image
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
let assets = root.appendingPathComponent("assets", isDirectory: true)
try FileManager.default.createDirectory(at: assets, withIntermediateDirectories: true)

let icon = renderIcon()
let hero = renderHero()
try savePNG(icon, to: assets.appendingPathComponent("icon.png"), size: icon.size)
try savePNG(hero, to: assets.appendingPathComponent("hero.png"), size: hero.size)

if FileManager.default.fileExists(atPath: assets.appendingPathComponent("menu-preview.png").path) {
  try FileManager.default.removeItem(at: assets.appendingPathComponent("menu-preview.png"))
}

print("Wrote \(assets.path)/icon.png and hero.png")
