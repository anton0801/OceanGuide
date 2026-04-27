import SwiftUI

// MARK: - Weather (13)

struct WeatherView: View {
    @EnvironmentObject var weatherVM: WeatherViewModel
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var notificationVM: NotificationViewModel
    @State private var animateRefresh = false

    var body: some View {
        NavigationView {
            OGBackground {
                ScrollView {
                    VStack(spacing: 16) {
                        header
                        currentCard
                        windWaveCard
                        hourlyCard
                        marineConditionsCard
                        alertActions
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .refreshable {
                    weatherVM.refresh()
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Weather").font(.ogTitle(28))
                Text("Updated \(formatted(weatherVM.lastUpdated))")
                    .font(.ogCaption(12))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button {
                appState.haptic(.light)
                withAnimation(.linear(duration: 0.6)) { animateRefresh.toggle() }
                weatherVM.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(OGTheme.ocean)
                    .padding(10)
                    .background(Circle().fill(OGTheme.ocean.opacity(0.15)))
                    .rotationEffect(.degrees(animateRefresh ? 360 : 0))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    private func formatted(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = appState.twentyFourHour ? "HH:mm" : "h:mm a"
        return f.string(from: d)
    }

    private var currentCard: some View {
        OGCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(OGTheme.oceanGradient)
                        .frame(width: 90, height: 90)
                    Image(systemName: weatherVM.current.symbol)
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(weatherVM.current.summary).font(.ogHeadline(18))
                    Text("\(Int(appState.tempUnit.convert(fromC: weatherVM.current.temperatureC)))\(appState.tempUnit.short)")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(OGTheme.oceanGradient)
                    Text("Humidity \(Int(weatherVM.current.humidity * 100))%, Pressure \(Int(weatherVM.current.pressureHPa)) hPa")
                        .font(.ogCaption(11))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }

    private var windWaveCard: some View {
        HStack(spacing: 10) {
            OGCard {
                VStack(spacing: 8) {
                    Label("Wind", systemImage: "wind")
                        .font(.ogCaption(12)).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(Int(weatherVM.current.windSpeedKnots))")
                            .font(.ogTitle(32))
                        Text("kn").font(.ogCaption(12)).foregroundColor(.secondary)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "location.north.fill")
                            .rotationEffect(.degrees(weatherVM.current.windDirection))
                            .foregroundColor(OGTheme.ocean)
                        Text("From \(weatherVM.current.windDirectionText)")
                            .font(.ogCaption(12))
                    }.foregroundColor(.secondary)
                }
            }
            OGCard {
                VStack(spacing: 8) {
                    Label("Waves", systemImage: "water.waves")
                        .font(.ogCaption(12)).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack(alignment: .firstTextBaseline) {
                        Text(String(format: "%.1f", weatherVM.current.waveHeightMeters))
                            .font(.ogTitle(32))
                        Text("m").font(.ogCaption(12)).foregroundColor(.secondary)
                    }
                    Text(waveDescription)
                        .font(.ogCaption(12))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var waveDescription: String {
        let h = weatherVM.current.waveHeightMeters
        if h < 0.5 { return "Calm sea" }
        else if h < 1.0 { return "Smooth waves" }
        else if h < 2.0 { return "Moderate seas" }
        else { return "Rough seas" }
    }

    private var hourlyCard: some View {
        OGCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Next 8 hours", systemImage: "clock")
                    .font(.ogHeadline(15))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(weatherVM.current.hourlyForecast) { h in
                            VStack(spacing: 6) {
                                Text("+\(h.hourOffset)h").font(.ogCaption(11)).foregroundColor(.secondary)
                                Image(systemName: h.symbol)
                                    .font(.system(size: 22))
                                    .foregroundStyle(OGTheme.oceanGradient)
                                Text("\(Int(appState.tempUnit.convert(fromC: h.temperatureC)))\(appState.tempUnit.short)")
                                    .font(.ogHeadline(13))
                                Text("\(Int(h.windSpeedKnots))kn")
                                    .font(.ogCaption(10))
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 60)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(OGTheme.ocean.opacity(0.06))
                            )
                        }
                    }
                }
            }
        }
    }

    private var marineConditionsCard: some View {
        OGCard {
            VStack(spacing: 14) {
                HStack {
                    Label("Marine Conditions", systemImage: "binoculars.fill")
                        .font(.ogHeadline(15))
                    Spacer()
                }
                row(icon: "eye.fill", title: "Visibility", value: String(format: "%.1f km", weatherVM.current.visibilityKm))
                row(icon: "barometer", title: "Pressure", value: "\(Int(weatherVM.current.pressureHPa)) hPa")
                row(icon: "drop.fill", title: "Humidity", value: "\(Int(weatherVM.current.humidity * 100))%")
                row(icon: "thermometer.medium", title: "Sea Temp", value: "\(Int(appState.tempUnit.convert(fromC: weatherVM.current.temperatureC - 4)))\(appState.tempUnit.short)")
            }
        }
    }

    private func row(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(OGTheme.ocean).frame(width: 22)
            Text(title).font(.ogBody(14))
            Spacer()
            Text(value).font(.ogHeadline(14))
        }
    }

    private var alertActions: some View {
        NavigationLink {
            AlertsView()
        } label: {
            OGCard {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(OGTheme.warning)
                        .font(.system(size: 22))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Marine Alerts").font(.ogHeadline(15))
                        Text("View active warnings & notices")
                            .font(.ogCaption(12)).foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Alerts (14)

struct AlertsView: View {
    @EnvironmentObject var alertsVM: AlertsViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        OGBackground {
            ScrollView {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(alertsVM.unreadCount) unread")
                                .font(.ogCaption(12)).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Mark all read") {
                            appState.haptic(.light)
                            alertsVM.markAllRead()
                        }
                        .font(.ogCaption(13))
                        .foregroundColor(OGTheme.ocean)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    if alertsVM.alerts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 56))
                                .foregroundColor(OGTheme.success)
                            Text("All clear").font(.ogHeadline(18))
                            Text("No active alerts. Stay vigilant.")
                                .font(.ogCaption(13)).foregroundColor(.secondary)
                        }
                        .padding(.top, 80)
                    }

                    ForEach(alertsVM.alerts) { alert in
                        AlertRow(alert: alert)
                            .padding(.horizontal, 16)
                            .onTapGesture {
                                alertsVM.markRead(alert)
                            }
                            .contextMenu {
                                Button("Mark as read") { alertsVM.markRead(alert) }
                                Button("Dismiss", role: .destructive) { alertsVM.dismiss(alert) }
                            }
                    }

                    Color.clear.frame(height: 100)
                }
            }
        }
        .navigationTitle("Alerts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AlertRow: View {
    let alert: MarineAlert

    var body: some View {
        OGCard {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(alert.severity.color.opacity(0.18)).frame(width: 44, height: 44)
                    Image(systemName: alert.severity.symbol)
                        .foregroundColor(alert.severity.color)
                        .font(.system(size: 20, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(alert.title).font(.ogHeadline(15))
                        if !alert.isRead {
                            Circle().fill(OGTheme.ocean).frame(width: 8, height: 8)
                        }
                    }
                    Text(alert.message).font(.ogCaption(13)).foregroundColor(.secondary)
                    Text(DateFormatter.dayShort.string(from: alert.date))
                        .font(.ogCaption(11)).foregroundColor(.secondary.opacity(0.7))
                }
                Spacer()
            }
        }
    }
}
