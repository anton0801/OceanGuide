import Foundation
import Combine

final class VesselViewModel: ObservableObject {
    @Published var vessel: Vessel
    private let key = "og.vessel"

    init() {
        if let saved: Vessel = Persistence.load(Vessel.self, key: "og.vessel") {
            self.vessel = saved
        } else {
            self.vessel = Vessel(
                name: "Sea Breeze",
                type: .yacht,
                registrationNumber: "ESP-2024-001",
                lengthMeters: 12.5,
                beamMeters: 4.2,
                maxSpeedKnots: 28,
                fuelCapacityLiters: 320,
                currentFuelLiters: 240,
                enginePower: 220,
                yearBuilt: 2021,
                notes: "Twin engine cruiser, GPS-equipped, life rafts onboard."
            )
            persist()
        }
    }

    func update(_ vessel: Vessel) {
        self.vessel = vessel
        persist()
    }

    func setFuel(_ liters: Double) {
        vessel.currentFuelLiters = max(0, min(vessel.fuelCapacityLiters, liters))
        persist()
    }

    func refill() {
        vessel.currentFuelLiters = vessel.fuelCapacityLiters
        persist()
    }

    func consumeFuel(liters: Double) {
        vessel.currentFuelLiters = max(0, vessel.currentFuelLiters - liters)
        persist()
    }

    private func persist() {
        Persistence.save(vessel, key: key)
    }
}
