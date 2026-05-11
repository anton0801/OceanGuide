import SwiftUI

// MARK: - Navigation Mode (11)

struct NavigationModeView: View {
    @EnvironmentObject var routeVM: RouteViewModel
    @EnvironmentObject var tripVM: TripViewModel
    @EnvironmentObject var vesselVM: VesselViewModel
    @EnvironmentObject var appState: AppState

    @State private var heading: Double = 87
    @State private var bearing: Double = 102
    @State private var crossTrackError: Double = 0.12
    @State private var nextWaypointETA: Int = 18

    private var route: Route? { routeVM.activeRoute ?? routeVM.routes.first }
    private var nextWP: Waypoint? { route?.waypoints.dropFirst().first ?? route?.waypoints.first }

    var body: some View {
        OGBackground {
            ScrollView {
                VStack(spacing: 16) {
                    headingCard
                    statsRow
                    nextWaypointCard
                    courseGuideCard

                    if let route, !tripVM.isTracking {
                        OGPrimaryButton(title: "Start Navigation", icon: "play.fill") {
                            appState.haptic(.medium)
                            tripVM.startTracking()
                            if !route.isActive { routeVM.setActive(route) }
                        }
                    } else if tripVM.isTracking {
                        OGSecondaryButton(title: "Stop Navigation", icon: "stop.fill") {
                            appState.haptic(.medium)
                            let _ = tripVM.stopTracking(routeName: route?.name ?? "Trip", vesselVM: vesselVM)
                            appState.notify(.success)
                        }
                    }

                    Color.clear.frame(height: 60)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
        .navigationTitle("Navigation Mode")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 1.0)) {
                    heading += Double.random(in: -2...2)
                    bearing += Double.random(in: -1...1)
                    crossTrackError = max(0, crossTrackError + Double.random(in: -0.04...0.05))
                }
            }
        }
    }

    private var headingCard: some View {
        OGCard {
            VStack(spacing: 14) {
                Text("HEADING")
                    .font(.ogCaption(11).bold())
                    .foregroundColor(.secondary)

                ZStack {
                    Circle()
                        .stroke(OGTheme.depth.opacity(0.2), lineWidth: 4)
                        .frame(width: 220, height: 220)

                    Circle()
                        .trim(from: 0, to: 0.25)
                        .stroke(OGTheme.ocean,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90 + heading))

                    ForEach(0..<24) { i in
                        Capsule()
                            .fill(i % 6 == 0 ? OGTheme.depth : OGTheme.depth.opacity(0.4))
                            .frame(width: 2, height: i % 6 == 0 ? 14 : 8)
                            .offset(y: -100)
                            .rotationEffect(.degrees(Double(i) * 15))
                    }

                    VStack(spacing: 0) {
                        Text("\(Int(heading))°")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundStyle(OGTheme.oceanGradient)
                        Text(headingText)
                            .font(.ogCaption(13).bold())
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 240)
            }
        }
    }

    private var headingText: String {
        let dirs = ["N","NE","E","SE","S","SW","W","NW"]
        let i = Int((heading + 22.5) / 45) & 7
        return dirs[i]
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            OGStatTile(title: "Bearing", value: "\(Int(bearing))°", unit: "", icon: "scope", color: OGTheme.depth)
            OGStatTile(
                title: "Speed",
                value: String(format: "%.1f", appState.speedUnit.convert(fromKnots: tripVM.liveSpeedKnots)),
                unit: appState.speedUnit.short,
                icon: "speedometer", color: OGTheme.ocean)
            OGStatTile(
                title: "XTE",
                value: String(format: "%.2f", crossTrackError),
                unit: "NM",
                icon: "arrow.left.and.right",
                color: crossTrackError > 0.5 ? OGTheme.danger : OGTheme.success)
        }
    }

    private var nextWaypointCard: some View {
        Group {
            if let wp = nextWP {
                OGCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Next Waypoint", systemImage: "flag.fill")
                            .font(.ogCaption(12)).foregroundColor(.secondary)
                        Text(wp.name).font(.ogTitle(20))
                        Text(wp.coordinateString).font(.ogMono(13)).foregroundColor(.secondary)

                        HStack(spacing: 14) {
                            Label("\(nextWaypointETA) min", systemImage: "clock")
                            Label("\(Int(bearing))° bearing", systemImage: "scope")
                        }
                        .font(.ogCaption(12))
                        .foregroundColor(.secondary)
                    }
                }
            } else {
                OGCard {
                    HStack {
                        Image(systemName: "info.circle.fill").foregroundColor(OGTheme.ocean)
                        Text("No active waypoints. Set up a route first.")
                            .font(.ogCaption(13))
                    }
                }
            }
        }
    }

    private var courseGuideCard: some View {
        OGCard {
            VStack(spacing: 10) {
                Label("Course Guide", systemImage: "arrow.triangle.turn.up.right.diamond")
                    .font(.ogCaption(12)).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                let diff = bearing - heading
                let text = abs(diff) < 5 ? "On course" : (diff > 0 ? "Turn right \(Int(abs(diff)))°" : "Turn left \(Int(abs(diff)))°")
                let color: Color = abs(diff) < 5 ? OGTheme.success : OGTheme.warning

                HStack(spacing: 12) {
                    Image(systemName: abs(diff) < 5 ? "checkmark.circle.fill" : (diff > 0 ? "arrow.turn.up.right" : "arrow.turn.up.left"))
                        .font(.system(size: 28))
                        .foregroundColor(color)
                    Text(text).font(.ogHeadline(17))
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Compass (12)

struct CompassView: View {
    @State private var heading: Double = 0
    @EnvironmentObject var appState: AppState
    @State private var holdHeading: Double? = nil

    var body: some View {
        OGBackground {
            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [OGTheme.depth.opacity(0.15), OGTheme.ocean.opacity(0.05)],
                                              startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 320, height: 320)

                    Circle()
                        .stroke(OGTheme.depth.opacity(0.3), lineWidth: 2)
                        .frame(width: 280, height: 280)

                    // Tick marks
                    ForEach(0..<72) { i in
                        let isMajor = i % 9 == 0
                        let isMid = i % 3 == 0
                        Capsule()
                            .fill(isMajor ? OGTheme.nightBlue : OGTheme.depth.opacity(isMid ? 0.6 : 0.3))
                            .frame(width: isMajor ? 3 : 1.2,
                                   height: isMajor ? 18 : (isMid ? 10 : 6))
                            .offset(y: -130)
                            .rotationEffect(.degrees(Double(i) * 5))
                    }

                    // Direction labels
                    ForEach(["N","E","S","W"], id: \.self) { dir in
                        let angle: Double = ["N":0, "E":90, "S":180, "W":270][dir] ?? 0
                        Text(dir)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundColor(dir == "N" ? OGTheme.coral : OGTheme.depth)
                            .offset(y: -110)
                            .rotationEffect(.degrees(angle))
                    }

                    // Needle
                    ZStack {
                        Capsule()
                            .fill(LinearGradient(colors: [OGTheme.coral, OGTheme.danger],
                                                 startPoint: .top, endPoint: .center))
                            .frame(width: 6, height: 110)
                            .offset(y: -55)
                        Capsule()
                            .fill(LinearGradient(colors: [OGTheme.depth, OGTheme.nightBlue],
                                                 startPoint: .center, endPoint: .bottom))
                            .frame(width: 6, height: 110)
                            .offset(y: 55)
                        Circle().fill(.white).frame(width: 22, height: 22)
                        Circle().fill(OGTheme.nightBlue).frame(width: 12, height: 12)
                    }
                    .rotationEffect(.degrees(-heading))
                }

                VStack(spacing: 4) {
                    Text("\(Int(heading))°")
                        .font(.system(size: 56, weight: .heavy, design: .rounded))
                        .foregroundStyle(OGTheme.oceanGradient)
                    Text(directionText)
                        .font(.ogHeadline(18))
                        .foregroundColor(.secondary)
                }

                if let hold = holdHeading {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill").foregroundColor(OGTheme.warning)
                        Text("Holding \(Int(hold))°").font(.ogHeadline(14))
                        Spacer()
                        Button("Release") {
                            holdHeading = nil
                            appState.haptic(.light)
                        }
                        .font(.ogHeadline(13))
                        .foregroundColor(OGTheme.danger)
                    }
                    .padding(14)
                    .background(OGCard { Color.clear })
                }

                HStack(spacing: 10) {
                    OGSecondaryButton(title: "Calibrate", icon: "arrow.triangle.2.circlepath") {
                        appState.haptic(.light)
                        withAnimation(.easeInOut(duration: 0.6)) {
                            heading = Double.random(in: 0..<360)
                        }
                    }
                    OGPrimaryButton(title: holdHeading == nil ? "Hold Heading" : "Holding…",
                                    icon: holdHeading == nil ? "lock.fill" : "lock.open.fill") {
                        appState.haptic(.medium)
                        holdHeading = holdHeading == nil ? heading : nil
                    }
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
                    withAnimation(.easeInOut(duration: 0.7)) {
                        heading = (heading + Double.random(in: -3...4)).truncatingRemainder(dividingBy: 360)
                        if heading < 0 { heading += 360 }
                    }
                }
            }
        }
        .navigationTitle("Compass")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var directionText: String {
        let dirs = ["North","Northeast","East","Southeast","South","Southwest","West","Northwest"]
        let i = Int((heading + 22.5) / 45) & 7
        return dirs[i]
    }
}


struct OceanGuideWebView: View {
    @State private var targetURL: String? = ""
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            if isActive, let urlString = targetURL, let url = URL(string: urlString) {
                WebContainer(url: url).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { initialize() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in reload() }
    }
    
    private func initialize() {
        let temp = UserDefaults.standard.string(forKey: SeabedKey.pushURL)
        let stored = UserDefaults.standard.string(forKey: SeabedKey.anchor) ?? ""
        targetURL = temp ?? stored
        isActive = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: SeabedKey.pushURL) }
    }
    
    private func reload() {
        if let temp = UserDefaults.standard.string(forKey: SeabedKey.pushURL), !temp.isEmpty {
            isActive = false
            targetURL = temp
            UserDefaults.standard.removeObject(forKey: SeabedKey.pushURL)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isActive = true }
        }
    }
}
