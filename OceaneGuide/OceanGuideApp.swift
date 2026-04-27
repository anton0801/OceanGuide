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

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(authVM)
                .environmentObject(vesselVM)
                .environmentObject(routeVM)
                .environmentObject(weatherVM)
                .environmentObject(tripVM)
                .environmentObject(alertsVM)
                .environmentObject(notificationVM)
                .environmentObject(checklistVM)
                .preferredColorScheme(appState.colorScheme)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if !appState.didLaunch {
                SplashView()
            } else if !appState.hasCompletedOnboarding {
                OnboardingView()
            } else if !authVM.isAuthenticated {
                WelcomeView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.didLaunch)
        .animation(.easeInOut(duration: 0.4), value: appState.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.4), value: authVM.isAuthenticated)
    }
}
