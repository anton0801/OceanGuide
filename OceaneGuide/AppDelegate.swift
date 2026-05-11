import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private var launchHost: LaunchHost!
    private let surfaceTender = SurfaceTender()
    private let pushDecoder = PushDecoder()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        surfaceTender.attributionRelay = { [weak self] data in
            self?.broadcastAttribution(data)
        }
        surfaceTender.coursesRelay = { [weak self] data in
            self?.broadcastCourses(data)
        }
        
        // Visitors обходят SDK
        launchHost = LaunchHost(visitors: [
            FirebaseVisitor(),
            MessagingVisitor(messagingDelegate: self, notificationDelegate: self),
            AppsFlyerVisitor(delegate: self, deeplinkDelegate: self)
        ])
        launchHost.invokeAll()
        
        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            pushDecoder.decode(remote)
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    @objc private func onActivation() {
        AppsFlyerVisitor.initiateTracking()
    }
    
    private func broadcastAttribution(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: .init("ConversionDataReceived"),
            object: nil,
            userInfo: ["conversionData": data]
        )
    }
    
    private func broadcastCourses(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: .init("deeplink_values"),
            object: nil,
            userInfo: ["deeplinksData": data]
        )
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        messaging.token { token, err in
            guard err == nil, let t = token else { return }
            
            UserDefaults.standard.set(t, forKey: SeabedKey.fcm)
            UserDefaults.standard.set(t, forKey: SeabedKey.push)
            UserDefaults(suiteName: OceanConstants.suiteTides)?.set(t, forKey: "shared_fcm")
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        pushDecoder.decode(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        pushDecoder.decode(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        pushDecoder.decode(userInfo)
        completionHandler(.newData)
    }
}

extension AppDelegate: AppsFlyerLibDelegate, DeepLinkDelegate {
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        surfaceTender.acceptAttribution(data)
    }
    
    func onConversionDataFail(_ error: Error) {
        surfaceTender.acceptAttribution([
            "error": true,
            "error_desc": error.localizedDescription
        ])
    }
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status,
              let link = result.deepLink else { return }
        
        surfaceTender.acceptCourses(link.clickEvent)
    }
}

protocol LaunchVisitor {
    func visit()
}

final class LaunchHost {
    private let visitors: [LaunchVisitor]
    
    init(visitors: [LaunchVisitor]) {
        self.visitors = visitors
    }
    
    func invokeAll() {
        for visitor in visitors {
            visitor.visit()
        }
    }
}

final class FirebaseVisitor: LaunchVisitor {
    func visit() {
        FirebaseApp.configure()
    }
}

final class MessagingVisitor: LaunchVisitor {
    
    private weak var messagingDelegate: MessagingDelegate?
    private weak var notificationDelegate: UNUserNotificationCenterDelegate?
    
    init(messagingDelegate: MessagingDelegate, notificationDelegate: UNUserNotificationCenterDelegate) {
        self.messagingDelegate = messagingDelegate
        self.notificationDelegate = notificationDelegate
    }
    
    func visit() {
        Messaging.messaging().delegate = messagingDelegate
        UNUserNotificationCenter.current().delegate = notificationDelegate
        UIApplication.shared.registerForRemoteNotifications()
    }
}

final class AppsFlyerVisitor: LaunchVisitor {
    
    private weak var delegate: AppsFlyerLibDelegate?
    private weak var deeplinkDelegate: DeepLinkDelegate?
    
    init(delegate: AppsFlyerLibDelegate, deeplinkDelegate: DeepLinkDelegate) {
        self.delegate = delegate
        self.deeplinkDelegate = deeplinkDelegate
    }
    
    func visit() {
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = OceanConstants.beaconKey
        sdk.appleAppID = OceanConstants.appNumber
        sdk.delegate = delegate
        sdk.deepLinkDelegate = deeplinkDelegate
        sdk.isDebug = false
    }
    
    static func initiateTracking() {
        if #available(iOS 14, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
}

final class SurfaceTender: NSObject {
    
    var attributionRelay: (([AnyHashable: Any]) -> Void)?
    var coursesRelay: (([AnyHashable: Any]) -> Void)?
    
    private var attributionBuffer: [AnyHashable: Any] = [:]
    private var coursesBuffer: [AnyHashable: Any] = [:]
    private var fuseTimer: Timer?
    
    func acceptAttribution(_ data: [AnyHashable: Any]) {
        attributionBuffer = data
        scheduleFuse()
        
        if !coursesBuffer.isEmpty {
            performFuse()
        }
    }
    
    func acceptCourses(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: SeabedKey.voyaged) else { return }
        
        coursesBuffer = data
        coursesRelay?(data)
        fuseTimer?.invalidate()
        
        if !attributionBuffer.isEmpty {
            performFuse()
        }
    }
    
    private func scheduleFuse() {
        fuseTimer?.invalidate()
        fuseTimer = Timer.scheduledTimer(
            withTimeInterval: 2.5,
            repeats: false
        ) { [weak self] _ in
            self?.performFuse()
        }
    }
    
    private func performFuse() {
        var combined = attributionBuffer
        
        for (k, v) in coursesBuffer {
            let prefixed = "deep_\(k)"
            if combined[prefixed] == nil {
                combined[prefixed] = v
            }
        }
        
        attributionRelay?(combined)
    }
}

final class PushDecoder: NSObject {
    
    func decode(_ payload: [AnyHashable: Any]) {
        guard let url = trace(payload) else { return }
        
        UserDefaults.standard.set(url, forKey: SeabedKey.pushURL)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            NotificationCenter.default.post(
                name: .init("LoadTempURL"),
                object: nil,
                userInfo: ["temp_url": url]
            )
        }
    }
    
    private func trace(_ payload: [AnyHashable: Any]) -> String? {
        if let direct = payload["url"] as? String {
            return direct
        }
        if let nested = payload["data"] as? [String: Any],
           let url = nested["url"] as? String {
            return url
        }
        if let aps = payload["aps"] as? [String: Any],
           let nested = aps["data"] as? [String: Any],
           let url = nested["url"] as? String {
            return url
        }
        if let custom = payload["custom"] as? [String: Any],
           let url = custom["target_url"] as? String {
            return url
        }
        return nil
    }
}
