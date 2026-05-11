import SwiftUI

@main
struct OceanGuideApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var vesselVM = VesselViewModel()
    @StateObject private var routeVM = RouteViewModel()
    @StateObject private var weatherVM = WeatherViewModel()
    @StateObject private var tripVM = TripViewModel()
    @StateObject private var alertsVM = AlertsViewModel()
    @StateObject private var notificationVM = NotificationViewModel()
    @StateObject private var checklistVM = ChecklistViewModel()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(appState)
                .environmentObject(authVM)
                .environmentObject(vesselVM)
                .environmentObject(routeVM)
                .environmentObject(weatherVM)
                .environmentObject(tripVM)
                .environmentObject(alertsVM)
                .environmentObject(notificationVM)
                .environmentObject(checklistVM)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding {
                OnboardingView()
            } else if !authVM.isAuthenticated {
                WelcomeView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.4), value: authVM.isAuthenticated)
        .preferredColorScheme(appState.colorScheme)
    }
}
