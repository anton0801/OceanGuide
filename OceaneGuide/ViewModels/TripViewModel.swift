import Foundation
import Combine

final class TripViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var isTracking: Bool = false
    @Published var liveStart: Date?
    @Published var liveDistanceNM: Double = 0
    @Published var liveSpeedKnots: Double = 0
    @Published var liveMaxSpeed: Double = 0
    @Published var liveAvgSpeed: Double = 0
    @Published var liveFuelUsed: Double = 0

    private let key = "og.trips"
    private var timer: Timer?

    init() {
        if let saved: [Trip] = Persistence.load([Trip].self, key: key) {
            self.trips = saved
        } else {
            seed()
        }
    }

    private func seed() {
        let cal = Calendar.current
        let trip1 = Trip(
            name: "Morning Patrol",
            startDate: cal.date(byAdding: .day, value: -3, to: Date())!,
            endDate: cal.date(byAdding: .hour, value: -68, to: Date())!,
            distanceNM: 24.6,
            maxSpeedKnots: 18.4,
            avgSpeedKnots: 12.1,
            fuelUsedLiters: 28.0,
            routeName: "Coastal Cruise",
            notes: "Calm seas, light breeze."
        )
        let trip2 = Trip(
            name: "Sunset Run",
            startDate: cal.date(byAdding: .day, value: -7, to: Date())!,
            endDate: cal.date(byAdding: .hour, value: -163, to: Date())!,
            distanceNM: 16.2,
            maxSpeedKnots: 14.2,
            avgSpeedKnots: 9.8,
            fuelUsedLiters: 19.0,
            routeName: "Open Sea Run",
            notes: "Beautiful sunset, slight chop."
        )
        trips = [trip1, trip2]
        persist()
    }

    func startTracking() {
        guard !isTracking else { return }
        isTracking = true
        liveStart = Date()
        liveDistanceNM = 0
        liveSpeedKnots = 0
        liveMaxSpeed = 0
        liveAvgSpeed = 0
        liveFuelUsed = 0

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stopTracking(routeName: String, vesselVM: VesselViewModel) -> Trip? {
        guard isTracking, let start = liveStart else { return nil }
        timer?.invalidate()
        timer = nil
        isTracking = false

        let trip = Trip(
            name: "Trip \(DateFormatter.short.string(from: start))",
            startDate: start,
            endDate: Date(),
            distanceNM: liveDistanceNM,
            maxSpeedKnots: liveMaxSpeed,
            avgSpeedKnots: liveAvgSpeed,
            fuelUsedLiters: liveFuelUsed,
            routeName: routeName,
            notes: ""
        )
        trips.insert(trip, at: 0)
        persist()
        vesselVM.consumeFuel(liters: liveFuelUsed)
        return trip
    }

    private func tick() {
        // Simulate realistic readings
        let base = liveSpeedKnots == 0 ? 8.0 : liveSpeedKnots
        let drift = Double.random(in: -1.2...1.5)
        let newSpeed = max(0, min(28, base + drift))
        liveSpeedKnots = newSpeed
        liveMaxSpeed = max(liveMaxSpeed, newSpeed)
        // Distance per second from knots: knots = NM/h => NM/sec = knots/3600
        liveDistanceNM += newSpeed / 3600.0
        if let start = liveStart {
            let hours = max(0.0001, Date().timeIntervalSince(start) / 3600.0)
            liveAvgSpeed = liveDistanceNM / hours
        }
        // Crude fuel burn estimate: 4L per NM
        liveFuelUsed = liveDistanceNM * 4.0
    }

    func deleteTrip(_ trip: Trip) {
        trips.removeAll { $0.id == trip.id }
        persist()
    }

    func clearAll() {
        trips.removeAll()
        persist()
    }

    var totalDistanceNM: Double { trips.reduce(0) { $0 + $1.distanceNM } }
    var totalDuration: TimeInterval { trips.reduce(0) { $0 + $1.duration } }
    var totalFuel: Double { trips.reduce(0) { $0 + $1.fuelUsedLiters } }

    private func persist() {
        Persistence.save(trips, key: key)
    }
}

extension DateFormatter {
    static let short: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()
    static let dayShort: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, HH:mm"
        return f
    }()
}
