import Foundation
import Combine
import UserNotifications

final class AlertsViewModel: ObservableObject {
    @Published var alerts: [MarineAlert] = []
    private let key = "og.alerts"

    init() {
        if let saved: [MarineAlert] = Persistence.load([MarineAlert].self, key: key) {
            self.alerts = saved
        } else {
            seed()
        }
    }

    private func seed() {
        alerts = [
            MarineAlert(title: "Storm Warning",
                        message: "Squall expected in your area within 6 hours. Wind gusts up to 35 knots.",
                        severity: .danger),
            MarineAlert(title: "Reduced Visibility",
                        message: "Fog rolling in along the coastline. Reduce speed and use radar.",
                        severity: .warning),
            MarineAlert(title: "Strong Currents",
                        message: "Tidal currents stronger than usual near Cabo de Palos.",
                        severity: .warning),
            MarineAlert(title: "Welcome Aboard",
                        message: "Ocean Guide is ready. Check your safety checklist before departure.",
                        severity: .info)
        ]
        persist()
    }

    func markRead(_ alert: MarineAlert) {
        if let i = alerts.firstIndex(where: { $0.id == alert.id }) {
            alerts[i].isRead = true
            persist()
        }
    }

    func markAllRead() {
        for i in alerts.indices { alerts[i].isRead = true }
        persist()
    }

    func dismiss(_ alert: MarineAlert) {
        alerts.removeAll { $0.id == alert.id }
        persist()
    }

    func add(_ alert: MarineAlert) {
        alerts.insert(alert, at: 0)
        persist()
    }

    var unreadCount: Int { alerts.filter { !$0.isRead }.count }

    private func persist() {
        Persistence.save(alerts, key: key)
    }
}

final class NotificationViewModel: ObservableObject {
    @AppStorageWrapper("og.pushEnabled") var pushEnabled: Bool = true
    @AppStorageWrapper("og.weatherAlertsEnabled") var weatherAlertsEnabled: Bool = true
    @AppStorageWrapper("og.tripRemindersEnabled") var tripRemindersEnabled: Bool = true
    @AppStorageWrapper("og.fuelWarningEnabled") var fuelWarningEnabled: Bool = true

    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var notifications: [AppNotification] = []
    private let key = "og.notifications"

    init() {
        if let saved: [AppNotification] = Persistence.load([AppNotification].self, key: key) {
            self.notifications = saved
        } else {
            seed()
        }
        refreshStatus()
    }

    private func seed() {
        notifications = [
            AppNotification(title: "Weather Update",
                            body: "Wind picking up to 18kn from NW. Plan accordingly.",
                            symbol: "wind"),
            AppNotification(title: "Maintenance Reminder",
                            body: "Engine oil check is due in 12 hours of operation.",
                            symbol: "wrench.and.screwdriver.fill"),
            AppNotification(title: "Trip Logged",
                            body: "Sunset Run was saved to your trip history.",
                            symbol: "checkmark.seal.fill")
        ]
        persist()
    }

    func add(_ notif: AppNotification) {
        notifications.insert(notif, at: 0)
        persist()
    }

    func markRead(_ notif: AppNotification) {
        if let i = notifications.firstIndex(where: { $0.id == notif.id }) {
            notifications[i].isRead = true
            persist()
        }
    }

    func markAllRead() {
        for i in notifications.indices { notifications[i].isRead = true }
        persist()
    }

    func clearAll() {
        notifications.removeAll()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        persist()
    }

    func refreshStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] s in
            DispatchQueue.main.async { self?.permissionStatus = s.authorizationStatus }
        }
    }

    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound,.badge]) { granted, _ in
            DispatchQueue.main.async {
                self.refreshStatus()
                completion?(granted)
            }
        }
    }

    func scheduleTripReminder(after seconds: TimeInterval = 5, title: String, body: String) {
        guard pushEnabled, tripRemindersEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
        add(AppNotification(title: title, body: body, symbol: "bell.badge.fill"))
    }

    func scheduleWeatherAlert(after seconds: TimeInterval = 5, title: String, body: String) {
        guard pushEnabled, weatherAlertsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
        add(AppNotification(title: title, body: body, symbol: "cloud.bolt.rain.fill"))
    }

    func cancelAllScheduled() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private func persist() {
        Persistence.save(notifications, key: key)
    }
}

// Property wrapper that mirrors @AppStorage but is usable inside a class
@propertyWrapper
final class AppStorageWrapper<Value: Codable> {
    let key: String
    let defaultValue: Value
    init(wrappedValue: Value, _ key: String) {
        self.key = key
        self.defaultValue = wrappedValue
    }
    var wrappedValue: Value {
        get {
            if let data = UserDefaults.standard.data(forKey: key),
               let v = try? JSONDecoder().decode(Value.self, from: data) {
                return v
            }
            return defaultValue
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: key)
            }
        }
    }
}
