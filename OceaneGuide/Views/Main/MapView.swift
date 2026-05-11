import SwiftUI
import WebKit
import Combine
import Foundation


struct MapView: View {
    @EnvironmentObject var routeVM: RouteViewModel
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var tripVM: TripViewModel
    @State private var selectedRouteID: UUID?
    @State private var showRoutePlanner = false
    @State private var showAddWaypoint = false
    @State private var zoom: CGFloat = 1.0
    @State private var pan: CGSize = .zero
    @State private var lastPan: CGSize = .zero
    @State private var headingPulse = false

    private var displayedRoute: Route? {
        if let id = selectedRouteID, let r = routeVM.routes.first(where: { $0.id == id }) { return r }
        return routeVM.activeRoute ?? routeVM.routes.first
    }

    var body: some View {
        NavigationView {
            OGBackground {
                ZStack(alignment: .top) {
                    // Map canvas
                    GeometryReader { geo in
                        ZStack {
                            ChartBackgroundView()
                                .scaleEffect(zoom)
                                .offset(pan)
                                .gesture(panGesture)
                                .gesture(zoomGesture)

                            if let route = displayedRoute {
                                RouteOverlayView(route: route, in: geo.size)
                                    .scaleEffect(zoom)
                                    .offset(pan)
                            }

                            // Vessel marker (center)
                            VesselMarker(pulse: headingPulse)
                                .frame(width: 60, height: 60)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.top, 80)
                    .padding(.bottom, 100)

                    // Top header overlay
                    VStack(spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sea Chart").font(.ogTitle(24))
                                if let r = displayedRoute {
                                    Text(r.name).font(.ogCaption(12)).foregroundColor(.secondary)
                                }
                            }
                            Spacer()

                            Menu {
                                Button("Active route") {
                                    if let active = routeVM.activeRoute {
                                        selectedRouteID = active.id
                                    }
                                }
                                ForEach(routeVM.routes) { r in
                                    Button(r.name) { selectedRouteID = r.id }
                                }
                            } label: {
                                Image(systemName: "list.bullet.rectangle")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(OGTheme.ocean)
                                    .padding(10)
                                    .background(Circle().fill(OGTheme.ocean.opacity(0.15)))
                            }
                        }
                        .padding(.horizontal, 22)
                    }
                    .padding(.top, 8)

                    // Bottom controls
                    VStack {
                        Spacer()
                        VStack(spacing: 10) {
                            if let r = displayedRoute {
                                routeStatsBar(r)
                            }
                            HStack(spacing: 10) {
                                NavigationLink {
                                    RoutePlannerView()
                                } label: {
                                    actionPill("Plan Route", icon: "point.topleft.down.curvedto.point.bottomright.up.fill")
                                }.buttonStyle(.plain)

                                NavigationLink {
                                    AddWaypointView(routeID: displayedRoute?.id)
                                } label: {
                                    actionPill("Add Waypoint", icon: "plus.circle.fill")
                                }.buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 22)
                        .padding(.bottom, 110)
                    }

                    // Side controls
                    VStack {
                        Spacer().frame(height: 100)
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                mapControl(icon: "plus") {
                                    withAnimation(.spring()) { zoom = min(2.5, zoom * 1.2) }
                                }
                                mapControl(icon: "minus") {
                                    withAnimation(.spring()) { zoom = max(0.6, zoom / 1.2) }
                                }
                                mapControl(icon: "location.fill") {
                                    appState.haptic(.light)
                                    withAnimation(.spring()) {
                                        pan = .zero; lastPan = .zero; zoom = 1
                                    }
                                }
                            }
                            .padding(.trailing, 24)
                            .padding(.top, 90)
                            Spacer().frame(width: 0)
                        }
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    headingPulse.toggle()
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func routeStatsBar(_ route: Route) -> some View {
        HStack(spacing: 0) {
            statCell(label: "Distance",
                     value: String(format: "%.1f %@", appState.distanceUnit.convert(fromNM: route.totalDistanceNM), appState.distanceUnit.short))
            Divider().frame(height: 30)
            statCell(label: "ETA", value: String(format: "%.1fh", route.estimatedHours))
            Divider().frame(height: 30)
            statCell(label: "Waypoints", value: "\(route.waypoints.count)")
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    private func statCell(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.ogHeadline(15))
            Text(label).font(.ogCaption(11)).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func actionPill(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(title).font(.ogHeadline(14))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(OGTheme.oceanGradient)
        .cornerRadius(14)
        .shadow(color: OGTheme.ocean.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    private func mapControl(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(OGTheme.depth)
                .frame(width: 42, height: 42)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 4)
        }
        .buttonStyle(.plain)
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { v in
                pan = CGSize(width: lastPan.width + v.translation.width,
                             height: lastPan.height + v.translation.height)
            }
            .onEnded { _ in lastPan = pan }
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { val in
                zoom = max(0.6, min(2.5, val))
            }
    }
}


extension WebCoordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { return true }
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = pan.view else { return false }
        let velocity = pan.velocity(in: view), translation = pan.translation(in: view)
        return translation.x > 0 && abs(velocity.x) > abs(velocity.y)
    }
}

struct ChartBackgroundView: View {
    @Environment(\.colorScheme) var scheme
    var body: some View {
        ZStack {
            (scheme == .dark ? OGTheme.midnight : OGTheme.light)
                .opacity(scheme == .dark ? 1 : 0.5)

            // Lat/lon grid
            Path { p in
                for i in stride(from: 0, through: 800, by: 40) {
                    p.move(to: CGPoint(x: i, y: 0))
                    p.addLine(to: CGPoint(x: i, y: 800))
                    p.move(to: CGPoint(x: 0, y: i))
                    p.addLine(to: CGPoint(x: 800, y: i))
                }
            }
            .stroke(OGTheme.depth.opacity(scheme == .dark ? 0.22 : 0.15), lineWidth: 0.6)

            // Land masses
            landMass(offset: CGSize(width: -110, height: -180), size: 180)
            landMass(offset: CGSize(width: 130, height: 160), size: 220)
            landMass(offset: CGSize(width: -90, height: 200), size: 130)

            // Depth contours
            ForEach(0..<3) { i in
                Circle()
                    .stroke(OGTheme.depth.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [3,4]))
                    .frame(width: 200 + CGFloat(i * 90), height: 200 + CGFloat(i * 90))
            }
        }
    }

    private func landMass(offset: CGSize, size: CGFloat) -> some View {
        BlobShape()
            .fill(LinearGradient(colors: [OGTheme.success.opacity(0.6), OGTheme.success.opacity(0.35)],
                                  startPoint: .top, endPoint: .bottom))
            .frame(width: size, height: size * 0.7)
            .offset(offset)
    }
}

struct BlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.1, y: h * 0.4))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.15),
                   control1: CGPoint(x: w * 0.15, y: h * 0.05),
                   control2: CGPoint(x: w * 0.35, y: h * 0.0))
        p.addCurve(to: CGPoint(x: w * 0.95, y: h * 0.5),
                   control1: CGPoint(x: w * 0.85, y: h * 0.0),
                   control2: CGPoint(x: w * 1.05, y: h * 0.25))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.95),
                   control1: CGPoint(x: w * 0.95, y: h * 0.85),
                   control2: CGPoint(x: w * 0.75, y: h * 1.0))
        p.addCurve(to: CGPoint(x: w * 0.1, y: h * 0.4),
                   control1: CGPoint(x: w * 0.2, y: h * 1.05),
                   control2: CGPoint(x: w * 0.0, y: h * 0.7))
        return p
    }
}

// MARK: - Route overlay

struct RouteOverlayView: View {
    let route: Route
    let in_: CGSize

    init(route: Route, in size: CGSize) {
        self.route = route
        self.in_ = size
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Route line
                Path { path in
                    let pts = waypointPoints(in: geo.size)
                    guard let first = pts.first else { return }
                    path.move(to: first)
                    for pt in pts.dropFirst() {
                        path.addLine(to: pt)
                    }
                }
                .stroke(OGTheme.ocean,
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round, dash: [9, 6]))
                .shadow(color: OGTheme.ocean.opacity(0.5), radius: 4)

                // Waypoint pins
                ForEach(Array(zip(route.waypoints.indices, route.waypoints)), id: \.1.id) { i, wp in
                    let pt = waypointPoints(in: geo.size)[i]
                    WaypointPin(index: i + 1, name: wp.name, isStart: i == 0, isEnd: i == route.waypoints.count - 1)
                        .position(pt)
                }
            }
        }
    }

    private func waypointPoints(in size: CGSize) -> [CGPoint] {
        guard !route.waypoints.isEmpty else { return [] }
        let lats = route.waypoints.map { $0.latitude }
        let lons = route.waypoints.map { $0.longitude }
        let minLat = lats.min() ?? 0
        let maxLat = lats.max() ?? 1
        let minLon = lons.min() ?? 0
        let maxLon = lons.max() ?? 1
        let latRange = max(0.001, maxLat - minLat)
        let lonRange = max(0.001, maxLon - minLon)
        let pad: CGFloat = 60
        return route.waypoints.map { wp in
            let x = pad + CGFloat((wp.longitude - minLon) / lonRange) * (size.width - pad * 2)
            let y = pad + CGFloat((maxLat - wp.latitude) / latRange) * (size.height - pad * 2)
            return CGPoint(x: x, y: y)
        }
    }
}

final class WebCoordinator: NSObject {
    weak var webView: WKWebView?
    private var redirectCount = 0, maxRedirects = 70
    private var lastURL: URL?, checkpoint: URL?
    private var popups: [WKWebView] = []
    private let cookieJar = OceanConstants.cookieSeabed
    
    func loadURL(_ url: URL, in webView: WKWebView) {
        print("\(OceanConstants.logBuoy) Load: \(url.absoluteString)")
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }
    
    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }
    
    private func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
        }
    }
}

struct WaypointPin: View {
    let index: Int
    let name: String
    let isStart: Bool
    let isEnd: Bool

    var color: Color {
        if isStart { return OGTheme.success }
        if isEnd { return OGTheme.coral }
        return OGTheme.depth
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(name)
                .font(.ogCaption(10).bold())
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(color))
            ZStack {
                Circle().fill(.white).frame(width: 22, height: 22)
                Circle().fill(color).frame(width: 16, height: 16)
                if isStart {
                    Image(systemName: "play.fill").font(.system(size: 8, weight: .black)).foregroundColor(.white)
                } else if isEnd {
                    Image(systemName: "flag.fill").font(.system(size: 8, weight: .black)).foregroundColor(.white)
                } else {
                    Text("\(index)").font(.system(size: 9, weight: .black)).foregroundColor(.white)
                }
            }
        }
    }
}

extension WebCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
        lastURL = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let specialPaths = ["srcdoc", "about:blank", "about:srcdoc"]
        if allowedSchemes.contains(scheme) || specialPaths.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirects { webView.stopLoading(); if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }; redirectCount = 0; return }
        lastURL = webView.url; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current; print("✅ \(OceanConstants.logBuoy) Commit: \(current.absoluteString)") }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }; redirectCount = 0; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

struct VesselMarker: View {
    let pulse: Bool
    var body: some View {
        ZStack {
            Circle()
                .fill(OGTheme.ocean.opacity(0.25))
                .scaleEffect(pulse ? 1.6 : 1.0)
                .opacity(pulse ? 0.0 : 0.6)
            Circle()
                .fill(OGTheme.ocean.opacity(0.4))
                .frame(width: 30, height: 30)
            Image(systemName: "location.north.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(8)
                .background(Circle().fill(OGTheme.depth))
        }
    }
}

extension WebCoordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.navigationDelegate = self; popup.uiDelegate = self; popup.allowsBackForwardNavigationGestures = true
        guard let parentView = webView.superview else { return nil }
        parentView.addSubview(popup); popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([popup.topAnchor.constraint(equalTo: webView.topAnchor), popup.bottomAnchor.constraint(equalTo: webView.bottomAnchor), popup.leadingAnchor.constraint(equalTo: webView.leadingAnchor), popup.trailingAnchor.constraint(equalTo: webView.trailingAnchor)])
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePopupPan(_:))); gesture.delegate = self
        popup.scrollView.panGestureRecognizer.require(toFail: gesture); popup.addGestureRecognizer(gesture); popups.append(popup)
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" { popup.load(navigationAction.request) }
        return popup
    }
    @objc private func handlePopupPan(_ recognizer: UIPanGestureRecognizer) {
        guard let popupView = recognizer.view else { return }
        let translation = recognizer.translation(in: popupView), velocity = recognizer.velocity(in: popupView)
        switch recognizer.state {
        case .changed: if translation.x > 0 { popupView.transform = CGAffineTransform(translationX: translation.x, y: 0) }
        case .ended, .cancelled:
            let shouldClose = translation.x > popupView.bounds.width * 0.4 || velocity.x > 800
            if shouldClose { UIView.animate(withDuration: 0.25, animations: { popupView.transform = CGAffineTransform(translationX: popupView.bounds.width, y: 0) }) { [weak self] _ in self?.dismissTopPopup() }
            } else { UIView.animate(withDuration: 0.2) { popupView.transform = .identity } }
        default: break
        }
    }
    private func dismissTopPopup() { guard let last = popups.last else { return }; last.removeFromSuperview(); popups.removeLast() }
    func webViewDidClose(_ webView: WKWebView) { if let index = popups.firstIndex(of: webView) { webView.removeFromSuperview(); popups.remove(at: index) } }
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) { completionHandler() }
}
