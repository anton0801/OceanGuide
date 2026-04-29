import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var vesselVM: VesselViewModel
    @EnvironmentObject var routeVM: RouteViewModel
    @EnvironmentObject var tripVM: TripViewModel
    @EnvironmentObject var alertsVM: AlertsViewModel
    @EnvironmentObject var notificationVM: NotificationViewModel
    @EnvironmentObject var checklistVM: ChecklistViewModel
    @Environment(\.colorScheme) var scheme

    @State private var showLogoutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var showClearDataConfirm = false
    @State private var pushAlertsEnabled = true
    @State private var pushTripEnabled = true
    @State private var pushWeatherEnabled = true

    var body: some View {
        OGBackground {
            ScrollView {
                VStack(spacing: 18) {
                    appearanceSection
                    unitsSection
                    notificationsSection
                    behaviorSection
                    dataSection
                    accountSection
                    aboutSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showLogoutConfirm) {
            Alert(
                title: Text("Log out?"),
                message: Text("You'll need to sign in again."),
                primaryButton: .destructive(Text("Log Out")) {
                    authVM.logout()
                    appState.notify(.warning)
                },
                secondaryButton: .cancel()
            )
        }
    }

    // MARK: Appearance

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            OGSectionHeader(title: "Appearance")
            OGCard {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(OGTheme.ocean)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(OGTheme.ocean.opacity(0.12)))
                        Text("Theme")
                            .font(.ogBody(14))
                            .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                        Spacer()
                    }
                    HStack(spacing: 8) {
                        ForEach(AppThemeMode.allCases) { mode in
                            Button {
                                appState.haptic(.light)
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    appState.themeMode = mode
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: mode.symbol)
                                        .font(.system(size: 18))
                                    Text(mode.title)
                                        .font(.ogCaption(11))
                                }
                                .foregroundColor(appState.themeMode == mode ? .white : (scheme == .dark ? .white : OGTheme.nightBlue))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(appState.themeMode == mode ? OGTheme.ocean : Color.gray.opacity(0.12))
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Units

    private var unitsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            OGSectionHeader(title: "Units")
            OGCard(padding: 0) {
                VStack(spacing: 0) {
                    unitRow(
                        title: "Distance",
                        icon: "map",
                        current: appState.distanceUnit.short,
                        options: DistanceUnit.allCases.map { ($0.rawValue, $0.short) },
                        selected: appState.distanceUnit.rawValue
                    ) { raw in
                        if let v = DistanceUnit(rawValue: raw) { appState.distanceUnit = v }
                    }
                    Divider().background(Color.gray.opacity(0.1)).padding(.leading, 50)
                    unitRow(
                        title: "Speed",
                        icon: "speedometer",
                        current: appState.speedUnit.short,
                        options: SpeedUnit.allCases.map { ($0.rawValue, $0.short) },
                        selected: appState.speedUnit.rawValue
                    ) { raw in
                        if let v = SpeedUnit(rawValue: raw) { appState.speedUnit = v }
                    }
                    Divider().background(Color.gray.opacity(0.1)).padding(.leading, 50)
                    unitRow(
                        title: "Temperature",
                        icon: "thermometer",
                        current: appState.tempUnit.short,
                        options: TempUnit.allCases.map { ($0.rawValue, $0.short) },
                        selected: appState.tempUnit.rawValue
                    ) { raw in
                        if let v = TempUnit(rawValue: raw) { appState.tempUnit = v }
                    }
                    Divider().background(Color.gray.opacity(0.1)).padding(.leading, 50)
                    toggleRow(
                        title: "24-Hour Time",
                        icon: "clock.fill",
                        isOn: Binding(get: { appState.twentyFourHour }, set: { appState.twentyFourHour = $0 })
                    )
                }
            }
        }
    }

    private func unitRow(title: String, icon: String, current: String, options: [(String, String)], selected: String, onSelect: @escaping (String) -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(OGTheme.ocean)
                .frame(width: 28, height: 28)
                .background(Circle().fill(OGTheme.ocean.opacity(0.12)))
            Text(title)
                .font(.ogBody(14))
                .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
            Spacer()
            Menu {
                ForEach(options, id: \.0) { opt in
                    Button {
                        appState.haptic(.light)
                        onSelect(opt.0)
                    } label: {
                        HStack {
                            Text(opt.0)
                            if selected == opt.0 {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(current)
                        .font(.ogHeadline(14))
                        .foregroundColor(OGTheme.ocean)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(OGTheme.ocean)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(OGTheme.ocean.opacity(0.12)))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func toggleRow(title: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(OGTheme.ocean)
                .frame(width: 28, height: 28)
                .background(Circle().fill(OGTheme.ocean.opacity(0.12)))
            Text(title)
                .font(.ogBody(14))
                .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(OGTheme.ocean)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: Notifications

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            OGSectionHeader(title: "Notifications")
            OGCard(padding: 0) {
                VStack(spacing: 0) {
                    toggleRow(
                        title: "Weather alerts",
                        icon: "cloud.bolt.fill",
                        isOn: $pushWeatherEnabled
                    )
                    Divider().background(Color.gray.opacity(0.1)).padding(.leading, 50)
                    toggleRow(
                        title: "Trip reminders",
                        icon: "calendar.badge.clock",
                        isOn: $pushTripEnabled
                    )
                    Divider().background(Color.gray.opacity(0.1)).padding(.leading, 50)
                    toggleRow(
                        title: "Marine alerts",
                        icon: "exclamationmark.triangle.fill",
                        isOn: $pushAlertsEnabled
                    )
                    Divider().background(Color.gray.opacity(0.1)).padding(.leading, 50)
                    NavigationLink { NotificationsView() } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(OGTheme.ocean)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(OGTheme.ocean.opacity(0.12)))
                            Text("Manage Notifications")
                                .font(.ogBody(14))
                                .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                }
            }
        }
    }

    // MARK: Behavior

    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            OGSectionHeader(title: "Behavior")
            OGCard(padding: 0) {
                VStack(spacing: 0) {
                    toggleRow(
                        title: "Haptic Feedback",
                        icon: "hand.tap.fill",
                        isOn: Binding(get: { appState.hapticsEnabled }, set: { appState.hapticsEnabled = $0 })
                    )
                    Divider().background(Color.gray.opacity(0.1)).padding(.leading, 50)
                    toggleRow(
                        title: "Auto-start Trip",
                        icon: "play.circle.fill",
                        isOn: Binding(get: { appState.autoStartTrip }, set: { appState.autoStartTrip = $0 })
                    )
                    Divider().background(Color.gray.opacity(0.1)).padding(.leading, 50)
                    toggleRow(
                        title: "Use Offline Maps",
                        icon: "wifi.slash",
                        isOn: Binding(get: { appState.offlineMapsEnabled }, set: { appState.offlineMapsEnabled = $0 })
                    )
                }
            }
        }
    }

    // MARK: Data

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            OGSectionHeader(title: "Data")
            OGCard(padding: 0) {
                VStack(spacing: 0) {
                    Button {
                        showClearDataConfirm = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(OGTheme.warning)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(OGTheme.warning.opacity(0.15)))
                            Text("Clear All App Data")
                                .font(.ogBody(14))
                                .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .alert(isPresented: $showClearDataConfirm) {
                Alert(
                    title: Text("Clear all data?"),
                    message: Text("Trips, alerts, notifications and checklist will be reset. Account stays."),
                    primaryButton: .destructive(Text("Clear")) {
                        tripVM.clearAll()
                        alertsVM.markAllRead()
                        notificationVM.clearAll()
                        checklistVM.clearAll()
                        appState.notify(.warning)
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    // MARK: Account

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            OGSectionHeader(title: "Account")
            OGCard(padding: 0) {
                VStack(spacing: 0) {
                    NavigationLink { ProfileView() } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(OGTheme.ocean)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(OGTheme.ocean.opacity(0.12)))
                            Text("Edit Profile")
                                .font(.ogBody(14))
                                .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                    Divider().background(Color.gray.opacity(0.1)).padding(.leading, 50)
                    Button {
                        showLogoutConfirm = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(OGTheme.warning)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(OGTheme.warning.opacity(0.15)))
                            Text("Log Out")
                                .font(.ogBody(14))
                                .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    Divider().background(Color.gray.opacity(0.1)).padding(.leading, 50)
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(OGTheme.danger)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(OGTheme.danger.opacity(0.15)))
                            Text("Delete Account")
                                .font(.ogBody(14))
                                .foregroundColor(OGTheme.danger)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .alert(isPresented: $showDeleteConfirm) {
                        Alert(
                            title: Text("Delete account?"),
                            message: Text("This permanently removes your account and all associated data. This cannot be undone."),
                            primaryButton: .destructive(Text("Delete Forever")) {
                                authVM.deleteAccount()
                                appState.notify(.error)
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            }
        }
    }

    // MARK: About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            OGSectionHeader(title: "About")
            OGCard {
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "ferry.fill")
                            .font(.system(size: 22))
                            .foregroundColor(OGTheme.ocean)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ocean Guide")
                                .font(.ogHeadline(15))
                                .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                            Text("Navigate with confidence")
                                .font(.ogCaption(11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("v1.0.0")
                            .font(.ogCaption(12))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.gray.opacity(0.12)))
                    }
                }
            }
        }
    }
}
