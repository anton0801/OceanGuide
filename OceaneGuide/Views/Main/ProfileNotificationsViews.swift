import SwiftUI
import UserNotifications

// MARK: - Profile View

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme
    @Environment(\.presentationMode) var presentationMode

    @State private var name: String = ""
    @State private var avatarSymbol: String = "person.crop.circle.fill"
    @State private var savedFlash = false

    private let avatarOptions = [
        "person.crop.circle.fill",
        "ferry.fill",
        "sailboat.fill",
        "fish.fill",
        "anchor",
        "compass.drawing",
        "binoculars.fill",
        "water.waves",
        "flag.fill",
        "star.fill"
    ]

    var body: some View {
        OGBackground {
            ScrollView {
                VStack(spacing: 18) {
                    avatarCard
                    formCard
                    accountInfoCard
                    OGPrimaryButton(title: "Save Profile", icon: "checkmark") {
                        save()
                    }
                    if savedFlash {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(OGTheme.success)
                            Text("Saved")
                                .font(.ogHeadline(13))
                                .foregroundColor(OGTheme.success)
                        }
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            name = authVM.currentUser?.name ?? ""
            avatarSymbol = authVM.currentUser?.avatarSymbol ?? "person.crop.circle.fill"
        }
    }

    private var avatarCard: some View {
        OGCard {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(OGTheme.oceanGradient)
                        .frame(width: 110, height: 110)
                        .shadow(color: OGTheme.ocean.opacity(0.4), radius: 16, x: 0, y: 8)
                    Image(systemName: avatarSymbol)
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundColor(.white)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(avatarOptions, id: \.self) { sym in
                            Button {
                                appState.haptic(.light)
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    avatarSymbol = sym
                                }
                            } label: {
                                Image(systemName: sym)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(avatarSymbol == sym ? .white : OGTheme.ocean)
                                    .frame(width: 48, height: 48)
                                    .background(
                                        Circle()
                                            .fill(avatarSymbol == sym ? OGTheme.ocean : OGTheme.ocean.opacity(0.12))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            OGSectionHeader(title: "Display Name")
            OGCard {
                OGTextField(title: "Name", icon: "person.fill", text: $name, capitalize: true)
            }
        }
    }

    private var accountInfoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            OGSectionHeader(title: "Account")
            OGCard(padding: 0) {
                VStack(spacing: 0) {
                    infoRow(label: "Email", value: authVM.currentUser?.email ?? "—", icon: "envelope.fill")
                    Divider().background(Color.gray.opacity(0.1)).padding(.leading, 50)
                    infoRow(label: "Account Type", value: (authVM.currentUser?.isDemo ?? false) ? "Demo" : "Standard", icon: "checkmark.seal.fill")
                }
            }
        }
    }

    private func infoRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(OGTheme.ocean)
                .frame(width: 28, height: 28)
                .background(Circle().fill(OGTheme.ocean.opacity(0.12)))
            Text(label)
                .font(.ogBody(14))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.ogHeadline(14))
                .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            appState.notify(.error)
            return
        }
        authVM.updateProfile(name: trimmed, avatarSymbol: avatarSymbol)
        appState.notify(.success)
        withAnimation { savedFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            withAnimation { savedFlash = false }
        }
    }
}

// MARK: - Notifications View

struct NotificationsView: View {
    @EnvironmentObject var notificationVM: NotificationViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme

    @State private var showClearConfirm = false

    var body: some View {
        OGBackground {
            ScrollView {
                VStack(spacing: 18) {
                    permissionCard
                    actionRow
                    if notificationVM.notifications.isEmpty {
                        emptyState
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            OGSectionHeader(title: "Notifications", subtitle: "\(notificationVM.notifications.count) total")
                            VStack(spacing: 8) {
                                ForEach(sorted) { notif in
                                    notifRow(notif)
                                }
                            }
                        }
                    }
                    scheduleSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showClearConfirm) {
            Alert(
                title: Text("Clear all notifications?"),
                message: Text("This cannot be undone."),
                primaryButton: .destructive(Text("Clear All")) {
                    notificationVM.clearAll()
                    appState.notify(.warning)
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            notificationVM.refreshStatus()
        }
    }

    private var sorted: [AppNotification] {
        notificationVM.notifications.sorted { $0.date > $1.date }
    }

    private var permissionCard: some View {
        let (icon, label, color) = statusInfo
        return OGCard {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(color.opacity(0.15)))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Permission")
                        .font(.ogCaption(11))
                        .foregroundColor(.secondary)
                    Text(label)
                        .font(.ogHeadline(15))
                        .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                }
                Spacer()
                if notificationVM.permissionStatus != .authorized {
                    Button {
                        appState.haptic()
                        notificationVM.requestPermission()
                    } label: {
                        Text("Enable")
                            .font(.ogHeadline(13))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(OGTheme.ocean))
                    }
                }
            }
        }
    }

    private var statusInfo: (String, String, Color) {
        switch notificationVM.permissionStatus {
        case .authorized: return ("checkmark.seal.fill", "Authorized", OGTheme.success)
        case .denied: return ("xmark.octagon.fill", "Denied — enable in Settings", OGTheme.danger)
        case .provisional: return ("checkmark.circle", "Provisional", OGTheme.warning)
        case .ephemeral: return ("hourglass", "Ephemeral", OGTheme.warning)
        case .notDetermined: return ("questionmark.circle.fill", "Not yet requested", OGTheme.warning)
        @unknown default: return ("questionmark.circle", "Unknown", .secondary)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            OGSecondaryButton(title: "Mark All Read", icon: "envelope.open") {
                appState.haptic()
                notificationVM.markAllRead()
            }
            OGGhostButton(title: "Clear All", icon: "trash") {
                showClearConfirm = true
            }
        }
    }

    private func notifRow(_ notif: AppNotification) -> some View {
        Button {
            appState.haptic(.light)
            notificationVM.markRead(notif)
        } label: {
            OGCard(padding: 14) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(notif.isRead ? Color.gray.opacity(0.15) : OGTheme.ocean.opacity(0.15))
                            .frame(width: 38, height: 38)
                        Image(systemName: notif.symbol)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(notif.isRead ? .secondary : OGTheme.ocean)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(notif.title)
                                .font(.ogHeadline(14))
                                .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                            if !notif.isRead {
                                Circle().fill(OGTheme.ocean).frame(width: 7, height: 7)
                            }
                            Spacer()
                            Text(timeText(notif.date))
                                .font(.ogCaption(11))
                                .foregroundColor(.secondary)
                        }
                        Text(notif.body)
                            .font(.ogCaption(12))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func timeText(_ date: Date) -> String {
        let elapsed = Date().timeIntervalSince(date)
        if elapsed < 60 { return "now" }
        if elapsed < 3600 { return "\(Int(elapsed / 60))m" }
        if elapsed < 86400 { return "\(Int(elapsed / 3600))h" }
        return DateFormatter.dayShort.string(from: date)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.slash")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No notifications yet")
                .font(.ogHeadline(15))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            OGSectionHeader(title: "Quick Schedule", subtitle: "Test a notification")
            VStack(spacing: 8) {
                scheduleButton(title: "Trip Reminder (5s)", icon: "calendar.badge.clock", color: OGTheme.ocean) {
                    notificationVM.scheduleTripReminder(after: 5, title: "Trip departure", body: "Your scheduled trip starts soon. Final checks?")
                    appState.notify(.success)
                }
                scheduleButton(title: "Weather Alert (5s)", icon: "cloud.bolt.rain.fill", color: OGTheme.warning) {
                    notificationVM.scheduleWeatherAlert(after: 5, title: "Weather changing", body: "Wind speed rising in your area.")
                    appState.notify(.success)
                }
                scheduleButton(title: "Cancel Pending", icon: "xmark.circle.fill", color: OGTheme.coral) {
                    notificationVM.cancelAllScheduled()
                    appState.notify(.warning)
                }
            }
        }
    }

    private func scheduleButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            appState.haptic()
            action()
        } label: {
            OGCard(padding: 14) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(color)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(color.opacity(0.15)))
                    Text(title)
                        .font(.ogHeadline(14))
                        .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
