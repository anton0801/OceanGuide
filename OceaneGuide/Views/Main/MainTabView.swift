import SwiftUI

enum MainTab: Int, CaseIterable {
    case dashboard, map, weather, vessel, more

    var title: String {
        switch self {
        case .dashboard: return "Bridge"
        case .map: return "Map"
        case .weather: return "Weather"
        case .vessel: return "Vessel"
        case .more: return "More"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "speedometer"
        case .map: return "map.fill"
        case .weather: return "cloud.sun.fill"
        case .vessel: return "sailboat.fill"
        case .more: return "square.grid.2x2.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selected: MainTab = .dashboard
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selected {
                case .dashboard: DashboardView()
                case .map: MapView()
                case .weather: WeatherView()
                case .vessel: VesselInfoView()
                case .more: MoreHubView()
                }
            }
            .transition(.opacity)

            CustomTabBar(selected: $selected)
        }
    }
}

struct CustomTabBar: View {
    @Binding var selected: MainTab
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases, id: \.rawValue) { tab in
                Button {
                    appState.haptic(.light)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selected = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if selected == tab {
                                Capsule()
                                    .fill(OGTheme.ocean.opacity(0.18))
                                    .frame(width: 50, height: 28)
                            }
                            Image(systemName: tab.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(selected == tab ? OGTheme.ocean : .secondary)
                                .scaleEffect(selected == tab ? 1.1 : 1.0)
                        }
                        Text(tab.title)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(selected == tab ? OGTheme.ocean : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 18)
        .padding(.top, 4)
        .background(
            Rectangle()
                .fill(scheme == .dark ? OGTheme.midnight.opacity(0.92) : Color.white.opacity(0.92))
                .overlay(
                    Rectangle()
                        .stroke(scheme == .dark ? Color.white.opacity(0.05) : OGTheme.light.opacity(0.7), lineWidth: 1)
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
