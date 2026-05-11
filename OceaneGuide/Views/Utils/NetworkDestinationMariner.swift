import Foundation
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit

final class NetworkDestinationMariner: DestinationMariner {
    
    private let session: URLSession
    private let pauses: [Double] = [50.0, 100.0, 200.0]
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }
    
    private var browserAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    
    func chart(seed: [String: Any]) async throws -> String {
        guard let endpoint = URL(string: OceanConstants.backendCove) else {
            throw OceanError.wreckage(cause: nil)
        }
        
        var body: [String: Any] = seed
        body["os"] = "iOS"
        body["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        body["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        body["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        body["store_id"] = "id\(OceanConstants.appNumber)"
        body["push_token"] = UserDefaults.standard.string(forKey: SeabedKey.push)
            ?? Messaging.messaging().fcmToken
        body["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(browserAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        var lastError: Error?
        
        for (idx, pause) in pauses.enumerated() {
            do {
                return try await onceTry(request)
            } catch OceanError.anchorRefused {
                throw OceanError.anchorRefused
            } catch OceanError.overflow {
                let waitTime = pause * Double(idx + 1)
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                continue
            } catch {
                lastError = error
                if idx < pauses.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(pause * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? OceanError.lineSnapped(cause: nil)
    }
    
    private func onceTry(_ request: URLRequest) async throws -> String {
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw OceanError.lineSnapped(cause: nil)
        }
        
        if http.statusCode == 404 {
            throw OceanError.anchorRefused
        }
        
        if http.statusCode == 429 {
            throw OceanError.overflow
        }
        
        guard (200...299).contains(http.statusCode) else {
            throw OceanError.lineSnapped(cause: nil)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OceanError.wreckage(cause: nil)
        }
        
        guard let ok = json["ok"] as? Bool else {
            throw OceanError.wreckage(cause: nil)
        }
        
        if !ok {
            throw OceanError.anchorRefused
        }
        
        guard let url = json["url"] as? String else {
            throw OceanError.wreckage(cause: nil)
        }
        
        return url
    }
}
