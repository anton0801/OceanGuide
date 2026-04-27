import Foundation
import Combine
import SwiftUI

final class WeatherViewModel: ObservableObject {
    @Published var current: WeatherCondition
    @Published var lastUpdated: Date = Date()
    @Published var isRefreshing: Bool = false

    init() {
        self.current = WeatherViewModel.makeSample(seed: Int(Date().timeIntervalSince1970) % 100)
    }

    func refresh() {
        isRefreshing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self = self else { return }
            self.current = WeatherViewModel.makeSample(seed: Int.random(in: 0...10_000))
            self.lastUpdated = Date()
            self.isRefreshing = false
        }
    }

    static func makeSample(seed: Int) -> WeatherCondition {
        var rng = SeededRandom(seed: seed)
        let temp = rng.double(15...28)
        let wind = rng.double(4...22)
        let waves = rng.double(0.3...2.4)
        let visibility = rng.double(6...20)
        let pressure = rng.double(998...1024)
        let humidity = rng.double(0.4...0.85)
        let dir = rng.double(0...359)

        let conditions: [(String, String)] = [
            ("Sunny & Calm", "sun.max.fill"),
            ("Partly Cloudy", "cloud.sun.fill"),
            ("Overcast", "cloud.fill"),
            ("Light Rain", "cloud.drizzle.fill"),
            ("Choppy Seas", "wind"),
            ("Clear Night", "moon.stars.fill")
        ]
        let pick = conditions[Int(rng.double(0...Double(conditions.count - 1)))]

        let hourly = (1...8).map { i -> HourlyWeather in
            let t = temp + rng.double(-3...3)
            let w = max(0, wind + rng.double(-5...5))
            let symbols = ["sun.max.fill","cloud.sun.fill","cloud.fill","cloud.drizzle.fill","wind"]
            return HourlyWeather(
                hourOffset: i,
                temperatureC: t,
                windSpeedKnots: w,
                symbol: symbols[Int(rng.double(0...Double(symbols.count - 1)))]
            )
        }

        return WeatherCondition(
            temperatureC: temp,
            windSpeedKnots: wind,
            windDirection: dir,
            waveHeightMeters: waves,
            visibilityKm: visibility,
            pressureHPa: pressure,
            humidity: humidity,
            summary: pick.0,
            symbol: pick.1,
            hourlyForecast: hourly
        )
    }
}

struct SeededRandom {
    var state: UInt64
    init(seed: Int) { state = UInt64(abs(seed) + 1) }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
    mutating func double(_ range: ClosedRange<Double>) -> Double {
        let r = Double(next() % 10_000) / 10_000.0
        return range.lowerBound + r * (range.upperBound - range.lowerBound)
    }
}
