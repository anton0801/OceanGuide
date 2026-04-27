import SwiftUI
import Combine

enum AppThemeMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    var symbol: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.stars.fill"
        }
    }
}

enum DistanceUnit: String, CaseIterable, Identifiable {
    case nauticalMiles = "Nautical Miles"
    case kilometers = "Kilometers"
    case miles = "Miles"
    var id: String { rawValue }
    var short: String {
        switch self {
        case .nauticalMiles: return "NM"
        case .kilometers: return "km"
        case .miles: return "mi"
        }
    }
    func convert(fromNM nm: Double) -> Double {
        switch self {
        case .nauticalMiles: return nm
        case .kilometers: return nm * 1.852
        case .miles: return nm * 1.15078
        }
    }
}

enum SpeedUnit: String, CaseIterable, Identifiable {
    case knots = "Knots"
    case kmh = "km/h"
    case mph = "mph"
    var id: String { rawValue }
    var short: String {
        switch self {
        case .knots: return "kn"
        case .kmh: return "km/h"
        case .mph: return "mph"
        }
    }
    func convert(fromKnots k: Double) -> Double {
        switch self {
        case .knots: return k
        case .kmh: return k * 1.852
        case .mph: return k * 1.15078
        }
    }
}

enum TempUnit: String, CaseIterable, Identifiable {
    case celsius = "Celsius"
    case fahrenheit = "Fahrenheit"
    var id: String { rawValue }
    var short: String { self == .celsius ? "°C" : "°F" }
    func convert(fromC c: Double) -> Double {
        self == .celsius ? c : c * 9 / 5 + 32
    }
}

final class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("themeMode") private var themeModeRaw: String = AppThemeMode.system.rawValue
    @AppStorage("distanceUnit") private var distanceUnitRaw: String = DistanceUnit.nauticalMiles.rawValue
    @AppStorage("speedUnit") private var speedUnitRaw: String = SpeedUnit.knots.rawValue
    @AppStorage("tempUnit") private var tempUnitRaw: String = TempUnit.celsius.rawValue
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("offlineMapsEnabled") var offlineMapsEnabled: Bool = false
    @AppStorage("autoStartTrip") var autoStartTrip: Bool = true
    @AppStorage("twentyFourHour") var twentyFourHour: Bool = true

    @Published var didLaunch: Bool = false

    var themeMode: AppThemeMode {
        get { AppThemeMode(rawValue: themeModeRaw) ?? .system }
        set { themeModeRaw = newValue.rawValue; objectWillChange.send() }
    }

    var distanceUnit: DistanceUnit {
        get { DistanceUnit(rawValue: distanceUnitRaw) ?? .nauticalMiles }
        set { distanceUnitRaw = newValue.rawValue; objectWillChange.send() }
    }

    var speedUnit: SpeedUnit {
        get { SpeedUnit(rawValue: speedUnitRaw) ?? .knots }
        set { speedUnitRaw = newValue.rawValue; objectWillChange.send() }
    }

    var tempUnit: TempUnit {
        get { TempUnit(rawValue: tempUnitRaw) ?? .celsius }
        set { tempUnitRaw = newValue.rawValue; objectWillChange.send() }
    }

    var colorScheme: ColorScheme? {
        switch themeMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

// MARK: - Persistence helper

enum Persistence {
    static func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    static func remove(key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
