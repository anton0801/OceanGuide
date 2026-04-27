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

// MARK: - Notification entry

struct AppNotification: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var body: String
    var date: Date = Date()
    var symbol: String = "bell.fill"
    var isRead: Bool = false
}
