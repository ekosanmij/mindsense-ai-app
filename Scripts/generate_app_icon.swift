#!/usr/bin/env swift

import AppKit
import Foundation

enum IconVariant {
    case standard
    case dark
    case tinted
}

func color(_ hex: UInt32, alpha: CGFloat = 1.0) -> CGColor {
    let r = CGFloat((hex >> 16) & 0xFF) / 255.0
    let g = CGFloat((hex >> 8) & 0xFF) / 255.0
    let b = CGFloat(hex & 0xFF) / 255.0
    return CGColor(red: r, green: g, blue: b, alpha: alpha)
}

func makeContext(size: Int) -> CGContext {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    guard let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    ) else {
        fatalError("Unable to create bitmap context.")
    }

    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    context.interpolationQuality = .high
    return context
}

func drawBackground(in context: CGContext, size: CGFloat, top: CGColor, bottom: CGColor) {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let gradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [top, bottom] as CFArray,
        locations: [0.0, 1.0]
    ) else {
        fatalError("Unable to create background gradient.")
    }

    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: size * 0.5, y: size),
        end: CGPoint(x: size * 0.5, y: 0),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
}

func pulsePath(size: CGFloat) -> CGPath {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: size * 0.26, y: size * 0.50))
    path.addLine(to: CGPoint(x: size * 0.40, y: size * 0.50))
    path.addQuadCurve(to: CGPoint(x: size * 0.47, y: size * 0.565), control: CGPoint(x: size * 0.44, y: size * 0.50))
    path.addQuadCurve(to: CGPoint(x: size * 0.55, y: size * 0.435), control: CGPoint(x: size * 0.51, y: size * 0.53))
    path.addQuadCurve(to: CGPoint(x: size * 0.62, y: size * 0.54), control: CGPoint(x: size * 0.58, y: size * 0.46))
    path.addLine(to: CGPoint(x: size * 0.72, y: size * 0.54))
    return path
}

func drawSymbol(in context: CGContext, size: CGFloat, variant: IconVariant) {
    let pulse = pulsePath(size: size)
    let pulseWidth = size * 0.082
    let dotRadius = pulseWidth * 0.42
    let dotCenter = CGPoint(x: size * 0.765, y: size * 0.54)

    switch variant {
    case .standard, .dark:
        context.saveGState()
        context.setShadow(offset: .zero, blur: size * 0.04, color: color(0x56D3FF, alpha: 0.40))
        context.addPath(pulse)
        context.setStrokeColor(color(0x56D3FF, alpha: 0.44))
        context.setLineWidth(pulseWidth * 1.38)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.strokePath()
        context.setFillColor(color(0x56D3FF, alpha: 0.30))
        context.fillEllipse(
            in: CGRect(
                x: dotCenter.x - dotRadius * 1.9,
                y: dotCenter.y - dotRadius * 1.9,
                width: dotRadius * 3.8,
                height: dotRadius * 3.8
            )
        )
        context.restoreGState()

        context.addPath(pulse)
        context.setStrokeColor(color(0xD7F4FF))
        context.setLineWidth(pulseWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.strokePath()

        let dotRect = CGRect(
            x: dotCenter.x - dotRadius,
            y: dotCenter.y - dotRadius,
            width: dotRadius * 2,
            height: dotRadius * 2
        )
        context.setFillColor(color(0xD7F4FF))
        context.fillEllipse(in: dotRect)

    case .tinted:
        context.addPath(pulse)
        context.setStrokeColor(color(0xFFFFFF))
        context.setLineWidth(pulseWidth * 1.02)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.strokePath()
        context.setFillColor(color(0xFFFFFF))
        context.fillEllipse(
            in: CGRect(
                x: dotCenter.x - dotRadius,
                y: dotCenter.y - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            )
        )
    }
}

func renderIcon(size: Int, variant: IconVariant) -> CGImage {
    let context = makeContext(size: size)
    let canvas = CGFloat(size)

    switch variant {
    case .standard:
        drawBackground(
            in: context,
            size: canvas,
            top: color(0x0E1520),
            bottom: color(0x070B10)
        )
    case .dark:
        drawBackground(
            in: context,
            size: canvas,
            top: color(0x121B28),
            bottom: color(0x060A0F)
        )
    case .tinted:
        context.clear(CGRect(x: 0, y: 0, width: canvas, height: canvas))
    }

    drawSymbol(in: context, size: canvas, variant: variant)

    guard let image = context.makeImage() else {
        fatalError("Unable to render icon image.")
    }
    return image
}

func writePNG(_ image: CGImage, to outputURL: URL) throws {
    let rep = NSBitmapImageRep(cgImage: image)
    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "LogoGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to encode PNG."])
    }
    try pngData.write(to: outputURL)
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
let appIconSetDir = root.appendingPathComponent("MindSense-AI-v1.0.0/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
let generatedDir = root.appendingPathComponent("Docs/Brand/logo/generated", isDirectory: true)

try FileManager.default.createDirectory(at: appIconSetDir, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: generatedDir, withIntermediateDirectories: true)

let outputs: [(String, Int, IconVariant, URL)] = [
    ("AppIcon-1024", 1024, .standard, appIconSetDir),
    ("AppIcon-1024-dark", 1024, .dark, appIconSetDir),
    ("AppIcon-1024-tinted", 1024, .tinted, appIconSetDir),
    ("logo-icon-1024", 1024, .standard, generatedDir),
    ("logo-icon-512", 512, .standard, generatedDir),
    ("favicon-48", 48, .standard, generatedDir),
    ("favicon-32", 32, .standard, generatedDir),
    ("favicon-16", 16, .standard, generatedDir)
]

for (name, size, variant, folder) in outputs {
    let image = renderIcon(size: size, variant: variant)
    let url = folder.appendingPathComponent("\(name).png")
    try writePNG(image, to: url)
    print("Generated \(url.path)")
}
