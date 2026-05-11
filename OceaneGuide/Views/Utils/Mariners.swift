import Foundation
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit
import UIKit
import UserNotifications

final class SupabaseVerificationMariner: VerificationMariner {
    
    func verify() async throws {
        do {
            
        } catch let error as OceanError {
            throw error
        } catch {
            print("\(OceanConstants.logBuoy) Verification error: \(error)")
            throw OceanError.verificationLost(cause: error)
        }
    }
}

final class NotificationConsentMariner: ConsentMariner {
    
    /// Single-shot async throws — простейший подход
    func summon() async throws -> Bool {
        return try await UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        )
    }
    
    func enlist() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}
