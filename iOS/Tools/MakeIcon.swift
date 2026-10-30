// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

// Beacon's app icon: a light on the Mac app's space gradient (Theme.spaceGradient), two rings going out from it.
//   swift iOS/Tools/MakeIcon.swift iOS/Beacon/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
import AppKit

let size = 1024
let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
let full = CGRect(x: 0, y: 0, width: size, height: size)
let center = CGPoint(x: CGFloat(size) / 2, y: CGFloat(size) / 2)

// The Mac app's space gradient: neutral greys into black, top-leading to bottom-trailing.
let background = CGGradient(colorsSpace: space, colors: [
    CGColor(srgbRed: 0.10, green: 0.10, blue: 0.11, alpha: 1), CGColor(srgbRed: 0.04, green: 0.04, blue: 0.05, alpha: 1),
    CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1),
] as CFArray, locations: [0, 0.55, 1])!
context.drawLinearGradient(background, start: CGPoint(x: 0, y: CGFloat(size)), end: CGPoint(x: CGFloat(size), y: 0), options: [])

// The glow, then two rings, then the light.
let glow = CGGradient(colorsSpace: space, colors: [
    CGColor(srgbRed: 0.04, green: 0.52, blue: 1, alpha: 0.55), CGColor(srgbRed: 0.04, green: 0.52, blue: 1, alpha: 0),
] as CFArray, locations: [0, 1])!
context.drawRadialGradient(glow, startCenter: center, startRadius: 0, endCenter: center, endRadius: 420, options: [])
for (radius, alpha) in [(300.0, 0.22), (200.0, 0.4)] {
    context.setStrokeColor(CGColor(srgbRed: 0.29, green: 0.64, blue: 1, alpha: alpha))
    context.setLineWidth(18)
    context.strokeEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
}
let light = CGGradient(colorsSpace: space, colors: [
    CGColor(srgbRed: 0.82, green: 0.92, blue: 1, alpha: 1), CGColor(srgbRed: 0.04, green: 0.52, blue: 1, alpha: 1),
] as CFArray, locations: [0, 1])!
context.saveGState()
context.addEllipse(in: CGRect(x: center.x - 104, y: center.y - 104, width: 208, height: 208))
context.clip()
context.drawRadialGradient(light, startCenter: CGPoint(x: center.x - 30, y: center.y + 30), startRadius: 0, endCenter: center, endRadius: 104, options: [.drawsAfterEndLocation])
context.restoreGState()

let rep = NSBitmapImageRep(cgImage: context.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
print("wrote \(output)")
