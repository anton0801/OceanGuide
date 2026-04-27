import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var vesselVM: VesselViewModel
    @EnvironmentObject var weatherVM: WeatherViewModel
    @EnvironmentObject var routeVM: RouteViewModel
    @EnvironmentObject var tripVM: TripViewModel
    @EnvironmentObject var alertsVM: AlertsViewModel

    @State private var showSOS = false
    @State private var showProfile = false
    @State private var heading: Double = 145
    @State private var positionLat: Double = 37.9760
    @State private var positionLng: Double = -0.6803

    var body: some View {
        NavigationView {
            OGBackground {
                ScrollView {
                    VStack(spacing: 18) {
                        header
                        positionCard
                        liveStatsRow
                        weatherSummaryCard
                        activeRouteCard
                        quickActions
                        recentAlertsCard
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }

                NavigationLink(isActive: $showSOS) { SOSView() } label: { EmptyView() }
                NavigationLink(isActive: $showProfile) { ProfileView() } label: { EmptyView() }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Animate heading slowly to feel alive
                Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
                    withAnimation(.easeInOut(duration: 1.5)) {
                        heading += Double.random(in: -3...4)
                        positionLat += Double.random(in: -0.0008...0.0008)
                        positionLng += Double.random(in: -0.0008...0.0008)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: header
    private var header: some View {
        HStack(spacing: 12) {
            Button {
                appState.haptic(.light)
                showProfile = true
            } label: {
                ZStack {
                    Circle()
                        .fill(OGTheme.oceanGradient)
                        .frame(width: 48, height: 48)
                    Image(systemName: authVM.currentUser?.avatarSymbol ?? "person.crop.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("Hello, Captain")
                    .font(.ogCaption(13))
                    .foregroundColor(.secondary)
                Text(authVM.currentUser?.name ?? "Mariner")
                    .font(.ogHeadline(20))
            }

            Spacer()

            Button {
                appState.haptic(.heavy)
                showSOS = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sos.circle.fill")
                    Text("SOS").font(.ogHeadline(14))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(LinearGradient(colors: [OGTheme.danger, OGTheme.coral],
                                              startPoint: .top, endPoint: .bottom))
                )
                .shadow(color: OGTheme.danger.opacity(0.5), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    // MARK: position card with live compass
    private var positionCard: some View {
        OGCard {
            VStack(spacing: 14) {
                HStack {
                    Label("Current Position", systemImage: "location.fill")
                        .font(.ogCaption(12))
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(OGTheme.success).frame(width: 6, height: 6)
                        Text("LIVE").font(.ogCaption(10).bold()).foregroundColor(OGTheme.success)
                    }
                }

                HStack(spacing: 16) {
                    // Mini compass
                    ZStack {
                        Circle()
                            .stroke(OGTheme.ocean.opacity(0.3), lineWidth: 2)
                            .frame(width: 84, height: 84)
                        ForEach(0..<8) { i in
                            Capsule()
                                .fill(OGTheme.ocean.opacity(0.4))
                                .frame(width: 1.5, height: 6)
                                .offset(y: -38)
                                .rotationEffect(.degrees(Double(i) * 45))
                        }
                        Capsule()
                            .fill(LinearGradient(colors: [OGTheme.coral, OGTheme.danger],
                                                 startPoint: .top, endPoint: .bottom))
                            .frame(width: 4, height: 36)
                            .offset(y: -10)
                            .rotationEffect(.degrees(heading))
                        Circle().fill(OGTheme.depth).frame(width: 10, height: 10)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: "%.4f° N", positionLat))
                            .font(.ogMono(15))
                        Text(String(format: "%.4f° W", abs(positionLng)))
                            .font(.ogMono(15))
                        HStack(spacing: 4) {
                            Image(systemName: "location.north.fill").font(.system(size: 10))
                            Text("Heading \(Int(heading))°")
                                .font(.ogCaption(12))
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: live stats
    private var liveStatsRow: some View {
        HStack(spacing: 10) {
            OGStatTile(
                title: "Speed",
                value: String(format: "%.1f", appState.speedUnit.convert(fromKnots: tripVM.isTracking ? tripVM.liveSpeedKnots : 0)),
                unit: appState.speedUnit.short,
                icon: "speedometer",
                color: OGTheme.ocean
            )
            OGStatTile(
                title: "Distance",
                value: String(format: "%.1f", appState.distanceUnit.convert(fromNM: tripVM.liveDistanceNM)),
                unit: appState.distanceUnit.short,
                icon: "ruler.fill",
                color: OGTheme.depth
            )
            OGStatTile(
                title: "Fuel",
                value: "\(Int(vesselVM.vessel.fuelPercentage * 100))",
                unit: "%",
                icon: "fuelpump.fill",
                color: vesselVM.vessel.fuelPercentage < 0.2 ? OGTheme.danger : OGTheme.success
            )
        }
    }

    // MARK: weather summary
    private var weatherSummaryCard: some View {
        OGCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(OGTheme.ocean.opacity(0.15))
                        .frame(width: 64, height: 64)
                    Image(systemName: weatherVM.current.symbol)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(OGTheme.oceanGradient)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(weatherVM.current.summary)
                        .font(.ogHeadline(17))
                    HStack(spacing: 12) {
                        Label("\(Int(appState.tempUnit.convert(fromC: weatherVM.current.temperatureC)))\(appState.tempUnit.short)",
                              systemImage: "thermometer")
                        Label("\(Int(weatherVM.current.windSpeedKnots))kn \(weatherVM.current.windDirectionText)",
                              systemImage: "wind")
                    }
                    .font(.ogCaption(12))
                    .foregroundColor(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.secondary)
            }
        }
    }

    // MARK: active route
    private var activeRouteCard: some View {
        Group {
            if let route = routeVM.activeRoute {
                OGCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Active Route", systemImage: "point.topleft.down.curvedto.point.bottomright.up.fill")
                                .font(.ogHeadline(15))
                            Spacer()
                            Text("ACTIVE")
                                .font(.ogCaption(10).bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(OGTheme.success))
                        }
                        Text(route.name).font(.ogTitle(20))

                        HStack(spacing: 14) {
                            Label(String(format: "%.1f %@",
                                         appState.distanceUnit.convert(fromNM: route.totalDistanceNM),
                                         appState.distanceUnit.short),
                                  systemImage: "ruler")
                            Label(String(format: "%.1fh ETA", route.estimatedHours),
                                  systemImage: "clock")
                            Label("\(route.waypoints.count) wp",
                                  systemImage: "flag.fill")
                        }
                        .font(.ogCaption(12))
                        .foregroundColor(.secondary)

                        HStack(spacing: 10) {
                            if tripVM.isTracking {
                                OGSecondaryButton(title: "Stop Trip", icon: "stop.fill") {
                                    let _ = tripVM.stopTracking(routeName: route.name, vesselVM: vesselVM)
                                    appState.notify(.success)
                                }
                            } else {
                                OGPrimaryButton(title: "Start Trip", icon: "play.fill") {
                                    appState.haptic(.medium)
                                    tripVM.startTracking()
                                }
                            }
                        }
                    }
                }
            } else {
                Button {
                    appState.haptic(.light)
                } label: {
                    OGCard {
                        HStack(spacing: 12) {
                            Image(systemName: "map.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(OGTheme.ocean)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("No active route")
                                    .font(.ogHeadline(15))
                                Text("Plan a route from the Map tab")
                                    .font(.ogCaption(12))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: quick actions
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            OGSectionHeader(title: "Quick Actions")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                NavigationLink { CompassView() } label: {
                    QuickActionTile(title: "Compass", icon: "safari.fill", color: OGTheme.depth)
                }.buttonStyle(.plain)
                NavigationLink { NavigationModeView() } label: {
                    QuickActionTile(title: "Navigation", icon: "location.north.line.fill", color: OGTheme.ocean)
                }.buttonStyle(.plain)
                NavigationLink { SafetyChecklistView() } label: {
                    QuickActionTile(title: "Safety Checklist", icon: "checklist", color: OGTheme.success)
                }.buttonStyle(.plain)
                NavigationLink { FuelTrackerView() } label: {
                    QuickActionTile(title: "Fuel Tracker", icon: "fuelpump.fill", color: OGTheme.warning)
                }.buttonStyle(.plain)
            }
        }
    }

    // MARK: alerts
    private var recentAlertsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            OGSectionHeader(
                title: "Latest Alerts",
                trailing: AnyView(
                    NavigationLink {
                        AlertsView()
                    } label: {
                        Text("See all").font(.ogCaption(13)).foregroundColor(OGTheme.ocean)
                    }
                )
            )
            VStack(spacing: 8) {
                ForEach(alertsVM.alerts.prefix(2)) { alert in
                    OGCard(padding: 14) {
                        HStack(spacing: 12) {
                            Image(systemName: alert.severity.symbol)
                                .foregroundColor(alert.severity.color)
                                .font(.system(size: 22))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(alert.title).font(.ogHeadline(14))
                                Text(alert.message).font(.ogCaption(12))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

struct QuickActionTile: View {
    let title: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.18))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(color)
            }
            Text(title)
                .font(.ogHeadline(14))
                .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(scheme == .dark ? Color.white.opacity(0.06) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(scheme == .dark ? Color.white.opacity(0.08) : OGTheme.light, lineWidth: 1)
        )
    }
}
