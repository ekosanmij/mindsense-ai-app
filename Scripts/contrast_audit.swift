import Foundation

struct ContrastPair {
    let name: String
    let foreground: RGB
    let background: RGB
    let kind: ContrastKind
    let minimumRatio: Double
}

enum ContrastKind: String {
    case textAA = "Text AA"
    case textAAA = "Text AAA"
    case nonTextInteractive = "Non-text interactive"
    case nonTextDecorative = "Non-text decorative"
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

let textAA = 4.5
let textAAA = 7.0
let nonTextInteractive = 3.0
let nonTextDecorative = 1.3

let white = RGB(255, 255, 255)
let nearBlack = RGB(17, 17, 17)

// DS-03 parity tokens from MindSensePalette.
let primaryLight = RGB(16, 115, 94)
let primaryDark = RGB(142, 224, 198)
let primaryTintLight = RGB(229, 245, 239)
let primaryTintDark = RGB(24, 39, 35)
let accentLoadLight = RGB(152, 94, 24)
let accentLoadDark = RGB(242, 191, 94)
let bgLight = RGB(248, 249, 247)
let bgDark = RGB(12, 14, 17)
let cardLight = RGB(240, 243, 245)
let cardDark = RGB(33, 36, 40)
let textPrimaryLight = RGB(17, 17, 17)
let textPrimaryDark = RGB(235, 239, 244)
let textSecondaryLight = RGB(75, 85, 99)
let textSecondaryDark = RGB(189, 198, 210)
let borderLight = RGB(199, 205, 212)
let borderDark = RGB(96, 104, 116)

let pairs: [ContrastPair] = [
    // Text on core backgrounds.
    ContrastPair(name: "textPrimary on bg (light)", foreground: textPrimaryLight, background: bgLight, kind: .textAAA, minimumRatio: textAAA),
    ContrastPair(name: "textPrimary on bg (dark)", foreground: textPrimaryDark, background: bgDark, kind: .textAAA, minimumRatio: textAAA),
    ContrastPair(name: "textPrimary on card (light)", foreground: textPrimaryLight, background: cardLight, kind: .textAAA, minimumRatio: textAAA),
    ContrastPair(name: "textPrimary on card (dark)", foreground: textPrimaryDark, background: cardDark, kind: .textAAA, minimumRatio: textAAA),
    ContrastPair(name: "textSecondary on bg (light)", foreground: textSecondaryLight, background: bgLight, kind: .textAA, minimumRatio: textAA),
    ContrastPair(name: "textSecondary on bg (dark)", foreground: textSecondaryDark, background: bgDark, kind: .textAA, minimumRatio: textAA),
    ContrastPair(name: "textSecondary on card (light)", foreground: textSecondaryLight, background: cardLight, kind: .textAA, minimumRatio: textAA),
    ContrastPair(name: "textSecondary on card (dark)", foreground: textSecondaryDark, background: cardDark, kind: .textAA, minimumRatio: textAA),

    // Accent text and CTA readability.
    ContrastPair(name: "onAccent(white) on primary (light)", foreground: white, background: primaryLight, kind: .textAA, minimumRatio: textAA),
    ContrastPair(name: "nearBlack on primary (dark)", foreground: nearBlack, background: primaryDark, kind: .textAA, minimumRatio: textAA),
    ContrastPair(name: "accentLoad on card (light)", foreground: accentLoadLight, background: cardLight, kind: .textAA, minimumRatio: textAA),
    ContrastPair(name: "accentLoad on card (dark)", foreground: accentLoadDark, background: cardDark, kind: .textAA, minimumRatio: textAA),

    // Non-text graphics.
    ContrastPair(name: "primary on bg (light)", foreground: primaryLight, background: bgLight, kind: .nonTextInteractive, minimumRatio: nonTextInteractive),
    ContrastPair(name: "primary on bg (dark)", foreground: primaryDark, background: bgDark, kind: .nonTextInteractive, minimumRatio: nonTextInteractive),
    ContrastPair(name: "border on card (light)", foreground: borderLight, background: cardLight, kind: .nonTextDecorative, minimumRatio: nonTextDecorative),
    ContrastPair(name: "border on card (dark)", foreground: borderDark, background: cardDark, kind: .nonTextDecorative, minimumRatio: nonTextDecorative)
]

var failures: [String] = []
var kindResults: [ContrastKind: (pass: Int, fail: Int)] = [:]
print("MindSense contrast audit")
print("========================")

for pair in pairs {
    let ratio = contrastRatio(pair.foreground, pair.background)
    let pass = ratio >= pair.minimumRatio
    let status = pass ? "PASS" : "FAIL"
    print("\(status) [\(pair.kind.rawValue)] \(pair.name): \(String(format: "%.2f", ratio)) (min \(String(format: "%.2f", pair.minimumRatio)))")
    var bucket = kindResults[pair.kind] ?? (pass: 0, fail: 0)
    if pass {
        bucket.pass += 1
    } else {
        bucket.fail += 1
    }
    kindResults[pair.kind] = bucket
    if !pass {
        failures.append(pair.name)
    }
}

print("------------------------")
for kind in [ContrastKind.textAAA, .textAA, .nonTextInteractive, .nonTextDecorative] {
    let bucket = kindResults[kind] ?? (pass: 0, fail: 0)
    print("\(kind.rawValue): \(bucket.pass) pass, \(bucket.fail) fail")
}

if failures.isEmpty {
    print("All contrast checks passed.")
    exit(0)
}

print("Contrast audit failed for: \(failures.joined(separator: ", "))")
exit(1)
