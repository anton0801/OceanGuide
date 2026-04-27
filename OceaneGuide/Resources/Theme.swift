import SwiftUI

enum OGTheme {
    // Brand palette
    static let ocean = Color(hex: "0EA5E9")       // primary
    static let depth = Color(hex: "0284C7")       // secondary deep
    static let light = Color(hex: "E0F2FE")       // foam / accent light
    static let nightBlue = Color(hex: "0F172A")   // dark navy
    static let midnight = Color(hex: "081120")    // even deeper
    static let foam = Color(hex: "F0F9FF")
    static let warning = Color(hex: "F59E0B")
    static let danger = Color(hex: "EF4444")
    static let success = Color(hex: "10B981")
    static let coral = Color(hex: "FB7185")

    // Gradients
    static let oceanGradient = LinearGradient(
        colors: [ocean, depth],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let deepGradient = LinearGradient(
        colors: [depth, nightBlue],
        startPoint: .top, endPoint: .bottom
    )

    static let surfaceGradient = LinearGradient(
        colors: [light.opacity(0.6), foam],
        startPoint: .top, endPoint: .bottom
    )

    static let darkBackground = LinearGradient(
        colors: [midnight, nightBlue],
        startPoint: .top, endPoint: .bottom
    )

    static let lightBackground = LinearGradient(
        colors: [foam, .white],
        startPoint: .top, endPoint: .bottom
    )

    static func adaptiveBackground(_ scheme: ColorScheme) -> LinearGradient {
        scheme == .dark ? darkBackground : lightBackground
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:(a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r)/255,
                  green: Double(g)/255,
                  blue: Double(b)/255,
                  opacity: Double(a)/255)
    }
}

extension Font {
    static func ogTitle(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func ogHeadline(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static func ogBody(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    static func ogCaption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    static func ogMono(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced)
    }
}
