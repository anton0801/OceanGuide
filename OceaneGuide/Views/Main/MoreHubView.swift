import SwiftUI

// MARK: - More Hub View

struct MoreHubView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var tripVM: TripViewModel
    @EnvironmentObject var alertsVM: AlertsViewModel
    @EnvironmentObject var notificationVM: NotificationViewModel
    @Environment(\.colorScheme) var scheme

    var body: some View {
        NavigationView {
            OGBackground {
                ScrollView {
                    VStack(spacing: 18) {
                        userCard
                        navigationGrid
                        statsTeaser
                        alertsTeaser
                        Spacer().frame(height: 12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var userCard: some View {
        NavigationLink { ProfileView() } label: {
            OGCard(padding: 16) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(OGTheme.oceanGradient)
                            .frame(width: 56, height: 56)
                            .shadow(color: OGTheme.ocean.opacity(0.4), radius: 10, x: 0, y: 4)
                        Image(systemName: authVM.currentUser?.avatarSymbol ?? "person.crop.circle.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(authVM.currentUser?.name ?? "Guest")
                            .font(.ogHeadline(17))
                            .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                        Text(authVM.currentUser?.email ?? "—")
                            .font(.ogCaption(12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var navigationGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            navCard(title: "Routes", icon: "point.topleft.down.curvedto.point.bottomright.up", color: OGTheme.ocean) {
                AnyView(RoutePlannerView())
            }
            navCard(title: "Compass", icon: "location.north.line.fill", color: OGTheme.depth) {
                AnyView(CompassView())
            }
            navCard(title: "Trip Log", icon: "list.bullet.rectangle", color: OGTheme.success) {
                AnyView(TripLogView())
            }
            navCard(title: "Statistics", icon: "chart.bar.fill", color: OGTheme.warning) {
                AnyView(StatisticsView())
            }
            navCard(title: "History", icon: "clock.arrow.circlepath", color: OGTheme.coral) {
                AnyView(HistoryView())
            }
            navCard(title: "Safety", icon: "checkmark.shield.fill", color: OGTheme.success) {
                AnyView(SafetyChecklistView())
            }
            navCard(title: "Fuel", icon: "fuelpump.fill", color: OGTheme.depth) {
                AnyView(FuelTrackerView())
            }
            navCard(title: "Offline Maps", icon: "map.fill", color: OGTheme.ocean) {
                AnyView(OfflineMapsView())
            }
            navCard(title: "Alerts", icon: "exclamationmark.triangle.fill", color: OGTheme.danger) {
                AnyView(AlertsView())
            }
            navCard(title: "Notifications", icon: "bell.fill", color: OGTheme.warning) {
                AnyView(NotificationsView())
            }
            navCard(title: "SOS", icon: "antenna.radiowaves.left.and.right", color: OGTheme.danger) {
                AnyView(SOSView())
            }
            navCard(title: "Settings", icon: "gearshape.fill", color: .secondary) {
                AnyView(SettingsView())
            }
        }
    }

    private func navCard<Content: View>(title: String, icon: String, color: Color, @ViewBuilder destination: @escaping () -> Content) -> some View {
        NavigationLink {
            destination()
        } label: {
            OGCard(padding: 14) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(color.opacity(0.15)))
                    Text(title)
                        .font(.ogHeadline(14))
                        .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var statsTeaser: some View {
        let totalNM = tripVM.trips.reduce(0) { $0 + $1.distanceNM }
        let totalTrips = tripVM.trips.count
        return NavigationLink { StatisticsView() } label: {
            OGCard(padding: 16) {
                HStack(spacing: 14) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(OGTheme.ocean)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(OGTheme.ocean.opacity(0.15)))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Lifetime Stats")
                            .font(.ogHeadline(15))
                            .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                        Text("\(totalTrips) trips · \(String(format: "%.1f", totalNM)) NM")
                            .font(.ogCaption(12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var alertsTeaser: some View {
        let unread = alertsVM.alerts.filter { !$0.isRead }.count
        return NavigationLink { AlertsView() } label: {
            OGCard(padding: 16) {
                HStack(spacing: 14) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(unread > 0 ? OGTheme.warning : OGTheme.success)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill((unread > 0 ? OGTheme.warning : OGTheme.success).opacity(0.15)))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Marine Alerts")
                            .font(.ogHeadline(15))
                            .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                        Text(unread > 0 ? "\(unread) unread" : "All caught up")
                            .font(.ogCaption(12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if unread > 0 {
                        Text("\(unread)")
                            .font(.ogHeadline(13))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(OGTheme.danger))
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
