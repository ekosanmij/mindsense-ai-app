import Foundation

struct ContrastPair {
    let name: String
    let foreground: RGB
    let background: RGB
    let minimumRatio: Double
}

struct RGB {
    let r: Double
    let g: Double
    let b: Double

    init(_ r: Double, _ g: Double, _ b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }

    private func channel(_ value: Double) -> Double {
        let normalized = value / 255.0
        if normalized <= 0.03928 {
            return normalized / 12.92
        }
        return pow((normalized + 0.055) / 1.055, 2.4)
    }

    var relativeLuminance: Double {
        (0.2126 * channel(r)) + (0.7152 * channel(g)) + (0.0722 * channel(b))
    }
}

func contrastRatio(_ foreground: RGB, _ background: RGB) -> Double {
    let l1 = foreground.relativeLuminance
    let l2 = background.relativeLuminance
    let lighter = max(l1, l2)
    let darker = min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)
}

let white = RGB(255, 255, 255)
let nearBlack = RGB(18, 22, 27)
let onAccentDark = RGB(18, 30, 39)

let pairs: [ContrastPair] = [
    // CTA/selected states.
    ContrastPair(name: "White on signalCoolStrong (light)", foreground: white, background: RGB(9, 87, 132), minimumRatio: 4.5),
    ContrastPair(name: "onAccent on signalCoolStrong (dark)", foreground: onAccentDark, background: RGB(90, 191, 228), minimumRatio: 4.5),
    ContrastPair(name: "White on signalCool (light)", foreground: white, background: RGB(12, 116, 170), minimumRatio: 4.5),
    ContrastPair(name: "onAccent on signalCool (dark)", foreground: onAccentDark, background: RGB(120, 213, 247), minimumRatio: 4.5),

    // Explicit metric/status colors against base surfaces.
    ContrastPair(name: "signalCoolStrong on surfaceRaised (light)", foreground: RGB(9, 87, 132), background: RGB(249, 251, 253), minimumRatio: 4.5),
    ContrastPair(name: "warning on surfaceRaised (light)", foreground: RGB(171, 98, 24), background: RGB(249, 251, 253), minimumRatio: 4.5),
    ContrastPair(name: "success on surfaceRaised (light)", foreground: RGB(25, 124, 84), background: RGB(249, 251, 253), minimumRatio: 4.5),
    ContrastPair(name: "signalCool on surfaceRaised (dark)", foreground: RGB(120, 213, 247), background: RGB(28, 39, 49), minimumRatio: 4.5),
    ContrastPair(name: "warning on surfaceRaised (dark)", foreground: RGB(236, 184, 96), background: RGB(28, 39, 49), minimumRatio: 4.5),
    ContrastPair(name: "success on surfaceRaised (dark)", foreground: RGB(112, 224, 178), background: RGB(28, 39, 49), minimumRatio: 4.5),

    // Default text anchors for primary readability.
    ContrastPair(name: "nearBlack on canvasTop (light)", foreground: nearBlack, background: RGB(247, 244, 239), minimumRatio: 7.0),
    ContrastPair(name: "white on canvasBottom (dark)", foreground: white, background: RGB(15, 23, 31), minimumRatio: 7.0)
]

var failures: [String] = []
print("MindSense contrast audit")
print("========================")

for pair in pairs {
    let ratio = contrastRatio(pair.foreground, pair.background)
    let pass = ratio >= pair.minimumRatio
    let status = pass ? "PASS" : "FAIL"
    print("\(status) \(pair.name): \(String(format: "%.2f", ratio)) (min \(String(format: "%.2f", pair.minimumRatio)))")
    if !pass {
        failures.append(pair.name)
    }
}

if failures.isEmpty {
    print("All contrast checks passed.")
    exit(0)
}

print("Contrast audit failed for: \(failures.joined(separator: ", "))")
exit(1)
