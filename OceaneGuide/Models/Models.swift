import Foundation
import SwiftUI

// MARK: - User

struct User: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var email: String
    var passwordHash: String
    var avatarSymbol: String = "person.crop.circle.fill"
    var isDemo: Bool = false
}

// MARK: - Vessel

struct SeabedReading {
    let samples: [String: String]
    let courses: [String: String]
    let anchor: String?
    let current: String?
    let pristine: Bool
    let conferred: Bool
    let dismissed: Bool
    let summonedAt: Date?
}

enum NavAction {
    case wait
    case raiseConsent
    case voyageToWeb
    case voyageToMain
    case offlineAlert
}

struct Vessel: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var type: VesselType
    var registrationNumber: String
    var lengthMeters: Double
    var beamMeters: Double
    var maxSpeedKnots: Double
    var fuelCapacityLiters: Double
    var currentFuelLiters: Double
    var enginePower: Int          // hp
    var yearBuilt: Int
    var notes: String

    var fuelPercentage: Double {
        guard fuelCapacityLiters > 0 else { return 0 }
        return min(1, max(0, currentFuelLiters / fuelCapacityLiters))
    }
}

enum VesselType: String, Codable, CaseIterable, Identifiable {
    case yacht, sailboat, motorboat, fishingBoat, dinghy, catamaran
    var id: String { rawValue }
    var title: String {
        switch self {
        case .yacht: return "Yacht"
        case .sailboat: return "Sailboat"
        case .motorboat: return "Motorboat"
        case .fishingBoat: return "Fishing Boat"
        case .dinghy: return "Dinghy"
        case .catamaran: return "Catamaran"
        }
    }
    var symbol: String {
        switch self {
        case .yacht: return "ferry.fill"
        case .sailboat: return "sailboat.fill"
        case .motorboat: return "powerplug.fill"
        case .fishingBoat: return "fish.fill"
        case .dinghy: return "circle.dashed.inset.filled"
        case .catamaran: return "water.waves"
        }
    }
}

// MARK: - Waypoint & Route

struct Waypoint: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var latitude: Double
    var longitude: Double
    var note: String = ""

    var coordinateString: String {
        String(format: "%.4f°, %.4f°", latitude, longitude)
    }
}

struct Route: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var createdAt: Date = Date()
    var waypoints: [Waypoint]
    var isActive: Bool = false

    var totalDistanceNM: Double {
        guard waypoints.count > 1 else { return 0 }
        var total = 0.0
        for i in 0..<(waypoints.count - 1) {
            total += haversineNM(waypoints[i], waypoints[i + 1])
        }
        return total
    }

    var estimatedHours: Double {
        // Assume average 8 knots
        guard totalDistanceNM > 0 else { return 0 }
        return totalDistanceNM / 8.0
    }

    private func haversineNM(_ a: Waypoint, _ b: Waypoint) -> Double {
        let R = 3440.065 // nautical miles
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let dLat = (b.latitude - a.latitude) * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let h = sin(dLat/2) * sin(dLat/2) +
                cos(lat1) * cos(lat2) * sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(h), sqrt(1 - h))
        return R * c
    }
}

struct ConsentTide {
    var conferred: Bool
    var dismissed: Bool
    var summonedAt: Date?
    
    static let calm = ConsentTide(conferred: false, dismissed: false, summonedAt: nil)
    
    var navigable: Bool {
        guard !conferred && !dismissed else { return false }
        if let date = summonedAt {
            let elapsed = Date().timeIntervalSince(date) / 86400
            return elapsed >= 3
        }
        return true
    }
}


// MARK: - Weather

struct WeatherCondition: Codable {
    var temperatureC: Double
    var windSpeedKnots: Double
    var windDirection: Double      // degrees
    var waveHeightMeters: Double
    var visibilityKm: Double
    var pressureHPa: Double
    var humidity: Double           // 0..1
    var summary: String
    var symbol: String
    var hourlyForecast: [HourlyWeather]

    var windDirectionText: String {
        let dirs = ["N","NE","E","SE","S","SW","W","NW"]
        let i = Int((windDirection + 22.5) / 45) & 7
        return dirs[i]
    }
}

struct HourlyWeather: Codable, Identifiable {
    var id: UUID = UUID()
    var hourOffset: Int
    var temperatureC: Double
    var windSpeedKnots: Double
    var symbol: String
}

// MARK: - Alerts

enum AlertSeverity: String, Codable {
    case info, warning, danger
    var color: Color {
        switch self {
        case .info: return OGTheme.ocean
        case .warning: return OGTheme.warning
        case .danger: return OGTheme.danger
        }
    }
    var symbol: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .danger: return "exclamationmark.octagon.fill"
        }
    }
}

struct MarineAlert: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var message: String
    var severity: AlertSeverity
    var date: Date = Date()
    var isRead: Bool = false
}

// MARK: - Trip

struct Trip: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var startDate: Date
    var endDate: Date
    var distanceNM: Double
    var maxSpeedKnots: Double
    var avgSpeedKnots: Double
    var fuelUsedLiters: Double
    var routeName: String
    var notes: String

    var duration: TimeInterval { endDate.timeIntervalSince(startDate) }
    var durationFormatted: String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        return "\(h)h \(m)m"
    }
}

// MARK: - Safety Checklist

struct ChecklistItem: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var detail: String
    var isChecked: Bool = false
    var category: String
}


enum OceanError: Error {
    case dryAttribution
    case verificationLost(cause: Error?)
    case anchorRefused  // 404 / ok:false
    case wreckage(cause: Error?)
    case lineSnapped(cause: Error?)
    case overflow
    case watchEnded
}

struct OceanConstants {
    static let appNumber = "6764065798"
    static let beaconKey = "6oGUm8aSZqiBYfET3QWfN9"
    static let suiteTides = "group.oceanguide.tides"
    static let cookieSeabed = "oceanguide_seabed"
    static let backendCove = "https://oceanguiide.com/config.php"
    static let logBuoy = "🌊 [OceanGuide]"
}

struct SeabedKey {
    static let samples = "og_samples"
    static let courses = "og_courses"
    static let anchor = "og_anchor"
    static let current = "og_current"
    static let voyaged = "og_voyaged"
    static let conferred = "og_conferred"
    static let dismissed = "og_dismissed"
    static let summoned = "og_summoned"
    static let pushURL = "temp_url"
    static let fcm = "fcm_token"
    static let push = "push_token"
}


struct AppNotification: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var body: String
    var date: Date = Date()
    var symbol: String = "bell.fill"
    var isRead: Bool = false
}

struct AttributionTide {
    var samples: [String: String]
    var courses: [String: String]
    
    static let calm = AttributionTide(samples: [:], courses: [:])
    
    var saturated: Bool { !samples.isEmpty }
    var organicCurrent: Bool { samples["af_status"] == "Organic" }
}

struct DestinationTide {
    var anchor: String?
    var current: String?
    var pristine: Bool
    var sealed: Bool
    
    static let calm = DestinationTide(anchor: nil, current: nil, pristine: true, sealed: false)
}
