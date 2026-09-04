#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Foundation

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "AgentsMailbox/Assets.xcassets/AppIcon.appiconset")
let sizes: [(name: String, pixels: Int)] = [
    ("AppIcon-16.png", 16),
    ("AppIcon-16@2x.png", 32),
    ("AppIcon-32.png", 32),
    ("AppIcon-32@2x.png", 64),
    ("AppIcon-128.png", 128),
    ("AppIcon-128@2x.png", 256),
    ("AppIcon-256.png", 256),
    ("AppIcon-256@2x.png", 512),
    ("AppIcon-512.png", 512),
    ("AppIcon-512@2x.png", 1024),
]

func scaled(_ value: CGFloat, for pixels: Int) -> CGFloat {
    value * CGFloat(pixels) / 1024
}

func roundedPath(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func render(pixels: Int) throws -> Data {
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    let context = CGContext(
        data: nil,
        width: pixels,
        height: pixels,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)

    let canvas = CGRect(x: 0, y: 0, width: pixels, height: pixels)
    context.clear(canvas)

    let plate = canvas.insetBy(dx: scaled(54, for: pixels), dy: scaled(54, for: pixels))
    context.saveGState()
    context.addPath(roundedPath(plate, radius: scaled(220, for: pixels)))
    context.clip()
    let plateGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            CGColor(red: 1, green: 1, blue: 1, alpha: 1),
            CGColor(red: 0.92, green: 0.95, blue: 1, alpha: 1),
        ] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(
        plateGradient,
        start: CGPoint(x: plate.minX, y: plate.maxY),
        end: CGPoint(x: plate.maxX, y: plate.minY),
        options: []
    )
    context.restoreGState()

    let tile = CGRect(
        x: scaled(202, for: pixels),
        y: scaled(202, for: pixels),
        width: scaled(620, for: pixels),
        height: scaled(620, for: pixels)
    )
    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: scaled(-24, for: pixels)),
        blur: scaled(42, for: pixels),
        color: CGColor(red: 0.15, green: 0.38, blue: 1, alpha: 0.28)
    )
    context.addPath(roundedPath(tile, radius: scaled(164, for: pixels)))
    context.clip()
    let tileGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            CGColor(red: 0.11, green: 0.63, blue: 1.0, alpha: 1),
            CGColor(red: 0.43, green: 0.28, blue: 0.98, alpha: 1),
        ] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(
        tileGradient,
        start: CGPoint(x: tile.minX, y: tile.maxY),
        end: CGPoint(x: tile.maxX, y: tile.minY),
        options: []
    )
    context.restoreGState()

    let envelope = CGRect(
        x: scaled(324, for: pixels),
        y: scaled(366, for: pixels),
        width: scaled(376, for: pixels),
        height: scaled(292, for: pixels)
    )
    let envelopePath = roundedPath(envelope, radius: scaled(54, for: pixels))
    context.addPath(envelopePath)
    context.setFillColor(CGColor(gray: 1, alpha: 0.96))
    context.fillPath()

    context.setStrokeColor(CGColor(red: 0.19, green: 0.40, blue: 0.95, alpha: 0.72))
    context.setLineWidth(scaled(24, for: pixels))
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.move(to: CGPoint(x: envelope.minX + scaled(32, for: pixels), y: envelope.maxY - scaled(44, for: pixels)))
    context.addLine(to: CGPoint(x: envelope.midX, y: envelope.midY - scaled(10, for: pixels)))
    context.addLine(to: CGPoint(x: envelope.maxX - scaled(32, for: pixels), y: envelope.maxY - scaled(44, for: pixels)))
    context.strokePath()

    guard let image = context.makeImage() else { throw CocoaError(.fileWriteUnknown) }
    let representation = NSBitmapImageRep(cgImage: image)
    guard let data = representation.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }
    return data
}

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
for item in sizes {
    try render(pixels: item.pixels).write(to: outputDirectory.appendingPathComponent(item.name), options: .atomic)
}
