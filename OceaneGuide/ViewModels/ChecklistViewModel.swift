import Foundation
import SwiftUI

final class ChecklistViewModel: ObservableObject {
    @Published var items: [ChecklistItem] = []
    private let key = "ocean_guide_checklist_v1"

    init() { load() }

    private func load() {
        if let saved = Persistence.load([ChecklistItem].self, key: key), !saved.isEmpty {
            items = saved
        } else {
            seed()
        }
    }

    private func seed() {
        items = [
            // Hull & Engine
            ChecklistItem(title: "Hull integrity", detail: "No visible cracks or damage", category: "Hull & Engine"),
            ChecklistItem(title: "Engine oil level", detail: "Within recommended range", category: "Hull & Engine"),
            ChecklistItem(title: "Engine cooling", detail: "Coolant topped up", category: "Hull & Engine"),
            ChecklistItem(title: "Bilge pump operational", detail: "Test before departure", category: "Hull & Engine"),
            // Navigation
            ChecklistItem(title: "GPS signal acquired", detail: "Confirm position fix", category: "Navigation"),
            ChecklistItem(title: "Compass calibrated", detail: "Heading deviation < 5°", category: "Navigation"),
            ChecklistItem(title: "Charts loaded", detail: "Region for planned route", category: "Navigation"),
            ChecklistItem(title: "Route plan filed", detail: "Share with shore contact", category: "Navigation"),
            // Safety Equipment
            ChecklistItem(title: "Life jackets aboard", detail: "One per person, USCG-approved", category: "Safety Equipment"),
            ChecklistItem(title: "Fire extinguisher", detail: "In date and accessible", category: "Safety Equipment"),
            ChecklistItem(title: "Flares & visual signals", detail: "Within expiration date", category: "Safety Equipment"),
            ChecklistItem(title: "First aid kit", detail: "Stocked and accessible", category: "Safety Equipment"),
            ChecklistItem(title: "VHF radio working", detail: "Test on channel 16", category: "Safety Equipment"),
            // Fuel & Supplies
            ChecklistItem(title: "Fuel tank topped up", detail: "Plus reserve for return", category: "Fuel & Supplies"),
            ChecklistItem(title: "Fresh water aboard", detail: "Min 2 L per person/day", category: "Fuel & Supplies"),
            ChecklistItem(title: "Provisions packed", detail: "Food for trip duration", category: "Fuel & Supplies"),
            // Weather & Conditions
            ChecklistItem(title: "Weather forecast checked", detail: "For departure window", category: "Weather & Conditions"),
            ChecklistItem(title: "Tide schedule reviewed", detail: "Departure & arrival ports", category: "Weather & Conditions"),
            ChecklistItem(title: "Wind conditions acceptable", detail: "Below vessel limits", category: "Weather & Conditions")
        ]
        persist()
    }

    private func seedasdsadasdd() {
        items = [
            // Hull & Engine
            ChecklistItem(title: "Hull integrity", detail: "No visible cracks or damage", category: "Hull & Engine"),
            ChecklistItem(title: "Engine oil level", detail: "Within recommended range", category: "Hull & Engine"),
            ChecklistItem(title: "Engine cooling", detail: "Coolant topped up", category: "Hull & Engine"),
            ChecklistItem(title: "Bilge pump operational", detail: "Test before departure", category: "Hull & Engine"),
            // Navigation
            ChecklistItem(title: "GPS signal acquired", detail: "Confirm position fix", category: "Navigation"),
            ChecklistItem(title: "Compass calibrated", detail: "Heading deviation < 5°", category: "Navigation"),
            ChecklistItem(title: "Charts loaded", detail: "Region for planned route", category: "Navigation"),
            ChecklistItem(title: "Route plan filed", detail: "Share with shore contact", category: "Navigation"),
            // Fuel & Supplies
            ChecklistItem(title: "Fuel tank topped up", detail: "Plus reserve for return", category: "Fuel & Supplies"),
            ChecklistItem(title: "Fresh water aboard", detail: "Min 2 L per person/day", category: "Fuel & Supplies"),
            ChecklistItem(title: "Provisions packed", detail: "Food for trip duration", category: "Fuel & Supplies"),
            // Weather & Conditions
            ChecklistItem(title: "Weather forecast checked", detail: "For departure window", category: "Weather & Conditions"),
            ChecklistItem(title: "Tide schedule reviewed", detail: "Departure & arrival ports", category: "Weather & Conditions"),
            ChecklistItem(title: "Wind conditions acceptable", detail: "Below vessel limits", category: "Weather & Conditions")
        ]
        persist()
    }

    func toggle(_ item: ChecklistItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isChecked.toggle()
        persist()
    }

    func resetAll() {
        for i in 0..<items.count { items[i].isChecked = false }
        persist()
    }

    func checkAll() {
        for i in 0..<items.count { items[i].isChecked = true }
        persist()
    }

    var progress: Double {
        guard !items.isEmpty else { return 0 }
        return Double(items.filter { $0.isChecked }.count) / Double(items.count)
    }

    var categoryOrder: [String] {
        var seen = Set<String>()
        var order: [String] = []
        for item in items where !seen.contains(item.category) {
            seen.insert(item.category)
            order.append(item.category)
        }
        return order
    }

    func items(in category: String) -> [ChecklistItem] {
        items.filter { $0.category == category }
    }

    func categoryProgress(_ category: String) -> (done: Int, total: Int) {
        let cat = items(in: category)
        return (cat.filter { $0.isChecked }.count, cat.count)
    }

    func clearAll() {
        items = []
        Persistence.remove(key: key)
        seed()
    }

    private func persist() {
        Persistence.save(items, key: key)
    }
}
