import SwiftUI
import Combine
import Network
import Foundation

struct SplashView: View {
    // Loop state
    @State private var cycle: Int = 0
    @State private var phase: BuildPhase = .idle
    @State private var sailX: CGFloat = 0
    @State private var networkMonitor = NWPathMonitor()
    @State private var sailY: CGFloat = -120
    
    // Continuous animations
    @State private var waveOffset: CGFloat = 0
    @State private var deepWaveOffset: CGFloat = 0
    @State private var foamOpacity: Double = 0.6
    @State private var glowPulse: Bool = false
    @StateObject private var presenter = OceanPresenter()
    @State private var titleAppear: Bool = false
    @State private var dotPulse: Int = 0
    
    // Lifecycle
    @State private var isActive: Bool = true
    @State private var cancellables = Set<AnyCancellable>()
    @State private var timers: [Timer] = []
    
    enum BuildPhase {
        case idle, hull, mast, sail, sailing, gone
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geo in
                let W = geo.size.width
                let H = geo.size.height
                let centerY = H * 0.52
                
                ZStack {
                    background
                    
                    NavigationLink(
                        destination: OceanGuideWebView().navigationBarHidden(true),
                        isActive: $presenter.navigateToWeb
                    ) { EmptyView() }
                    
                    NavigationLink(
                        destination: RootView().navigationBarBackButtonHidden(true),
                        isActive: $presenter.navigateToMain
                    ) { EmptyView() }
                    
                    // Glow halo behind ship
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "0EA5E9").opacity(0.35),
                                    Color(hex: "0EA5E9").opacity(0.0)
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 220
                            )
                        )
                        .frame(width: 440, height: 440)
                        .position(x: W / 2 + sailX, y: centerY - 30)
                        .scaleEffect(glowPulse ? 1.05 : 0.92)
                        .blur(radius: 20)
                        .opacity(phase == .gone || phase == .idle ? 0 : 0.9)
                    
                    // Ambient floating particles
                    ParticleField(active: isActive)
                        .frame(width: W, height: H)
                        .opacity(0.55)
                    
                    // Waves layer (back)
                    WaveShape(amplitude: 14, frequency: 1.4, phase: deepWaveOffset)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "0284C7").opacity(0.55),
                                    Color(hex: "0369A1").opacity(0.85)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(height: H * 0.45)
                        .offset(y: H - H * 0.32)
                        .blur(radius: 0.5)
                    
                    // Waves layer (front) with foam
                    ZStack(alignment: .top) {
                        WaveShape(amplitude: 18, frequency: 1.8, phase: waveOffset)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "0EA5E9").opacity(0.85),
                                        Color(hex: "0284C7")
                                    ],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                        // Foam highlight running along the crest
                        WaveShape(amplitude: 18, frequency: 1.8, phase: waveOffset)
                            .stroke(
                                Color.white.opacity(foamOpacity),
                                style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [3, 6])
                            )
                            .blur(radius: 0.6)
                        // Foam bubbles
                        FoamLayer(phase: waveOffset, active: isActive)
                            .opacity(0.85)
                    }
                    .frame(height: H * 0.40)
                    .offset(y: H - H * 0.28)
                    .compositingGroup()
                    
                    // Ship — assembled in pieces
                    shipView
                        .position(x: W / 2 + sailX, y: centerY + sailY)
                        .opacity(phase == .idle || phase == .gone ? 0 : 1)
                    
                    // Title + tagline
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: "sailboat.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .opacity(0.85)
                            Text("OCEAN GUIDE")
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .tracking(4)
                                .foregroundColor(.white)
                        }
                        Text("Navigate with confidence")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.7))
                        
                        // Loading dots
                        HStack(spacing: 7) {
                            ForEach(0..<3) { i in
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 6, height: 6)
                                    .opacity(dotPulse == i ? 1.0 : 0.3)
                                    .scaleEffect(dotPulse == i ? 1.4 : 1.0)
                                    .animation(.easeInOut(duration: 0.35), value: dotPulse)
                            }
                        }
                        .padding(.top, 10)
                    }
                    .position(x: W / 2, y: H * 0.18)
                    .opacity(titleAppear ? 1 : 0)
                    .offset(y: titleAppear ? 0 : -10)
                    
                    // Glass overlay vignette (premium feel)
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.0),
                            Color.black.opacity(0.0),
                            Color.black.opacity(0.18)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
                }
                .onDisappear { stop() }
                .fullScreenCover(isPresented: $presenter.showPermissionPrompt) {
                    OceanGuideConsentView(presenter: presenter)
                }
                .fullScreenCover(isPresented: $presenter.showOfflineView) {
                    OfflineView()
                }
                .onAppear {
                    setupStreams()
                    start(width: W)
                    setupNetworkMonitoring()
                    presenter.wakeUp()
                }
            }
            .ignoresSafeArea()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: Background
    
    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "0B1424"),
                    Color(hex: "0F2540"),
                    Color(hex: "0A2A4A")
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle light rays from top
            RadialGradient(
                colors: [
                    Color(hex: "38BDF8").opacity(0.18),
                    Color.clear
                ],
                center: .init(x: 0.5, y: -0.05),
                startRadius: 30,
                endRadius: 420
            )
            .ignoresSafeArea()
            
            // Frosted glass orbs for depth
            Circle()
                .fill(Color(hex: "0EA5E9").opacity(0.10))
                .frame(width: 280, height: 280)
                .blur(radius: 40)
                .offset(x: -120, y: -260)
            Circle()
                .fill(Color(hex: "06B6D4").opacity(0.10))
                .frame(width: 220, height: 220)
                .blur(radius: 40)
                .offset(x: 130, y: 280)
        }
    }
    
    // MARK: Ship view (assembled in pieces, single composed shape with masks)
    
    private var shipView: some View {
        ZStack {
            // SAIL (top piece) — appears last
            SailShape()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.85)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    SailShape()
                        .stroke(Color.white.opacity(0.6), lineWidth: 0.8)
                )
                .shadow(color: Color(hex: "0EA5E9").opacity(0.5), radius: 8, x: 0, y: 2)
                .frame(width: 56, height: 70)
                .offset(x: 6, y: -56)
                .scaleEffect(sailScale, anchor: .bottom)
                .opacity(sailOpacity)
            
            // Small jib sail
            JibShape()
                .fill(Color.white.opacity(0.92))
                .frame(width: 30, height: 50)
                .offset(x: -18, y: -46)
                .scaleEffect(sailScale, anchor: .bottom)
                .opacity(sailOpacity * 0.95)
            
            // MAST (middle piece)
            RoundedRectangle(cornerRadius: 1.2)
                .fill(Color(hex: "F8FAFC"))
                .frame(width: 2.5, height: 90)
                .offset(y: -45)
                .scaleEffect(y: mastScale, anchor: .bottom)
                .opacity(mastOpacity)
                .shadow(color: .white.opacity(0.4), radius: 2)
            
            // HULL (bottom piece) — appears first
            HullShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "1E293B"),
                            Color(hex: "0F172A")
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .overlay(
                    HullShape()
                        .stroke(Color(hex: "38BDF8").opacity(0.5), lineWidth: 1)
                )
                .frame(width: 90, height: 28)
                .offset(y: 4)
                .scaleEffect(hullScale, anchor: .bottom)
                .opacity(hullOpacity)
            
            // Hull stripe (deck line)
            Rectangle()
                .fill(Color(hex: "38BDF8").opacity(0.7))
                .frame(width: 70, height: 1)
                .offset(y: -2)
                .opacity(hullOpacity)
            
            // Tiny window
            Circle()
                .fill(Color(hex: "FBBF24").opacity(0.9))
                .frame(width: 4, height: 4)
                .offset(x: 18, y: 4)
                .opacity(hullOpacity)
                .shadow(color: Color(hex: "FBBF24"), radius: 4)
        }
    }
    
    private func setupStreams() {
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { data in
                presenter.feedAttribution(data)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { data in
                presenter.feedCourses(data)
            }
            .store(in: &cancellables)
    }
    
    // Per-piece animation values
    private var hullOpacity: Double {
        switch phase {
        case .idle, .gone: return 0
        case .hull: return 1
        case .mast, .sail, .sailing: return 1
        }
    }
    private var hullScale: CGFloat {
        switch phase {
        case .idle, .gone: return 0.4
        default: return 1
        }
    }
    private var mastOpacity: Double {
        switch phase {
        case .idle, .hull, .gone: return 0
        case .mast, .sail, .sailing: return 1
        }
    }
    private var mastScale: CGFloat {
        switch phase {
        case .idle, .hull, .gone: return 0
        default: return 1
        }
    }
    private var sailOpacity: Double {
        switch phase {
        case .idle, .hull, .mast, .gone: return 0
        case .sail, .sailing: return 1
        }
    }
    private var sailScale: CGFloat {
        switch phase {
        case .idle, .hull, .mast, .gone: return 0.2
        default: return 1
        }
    }
    
    // MARK: Lifecycle
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                presenter.networkConnectivityChanged(path.status == .satisfied)
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
    
    private func start(width: CGFloat) {
        isActive = true
        
        // Continuous water animation
        withAnimation(.linear(duration: 3.2).repeatForever(autoreverses: false)) {
            waveOffset = .pi * 2
        }
        withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: false)) {
            deepWaveOffset = .pi * 2
        }
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            foamOpacity = 0.95
        }
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            glowPulse = true
        }
        
        // Title fade-in
        withAnimation(.easeOut(duration: 0.7).delay(0.2)) {
            titleAppear = true
        }
        
        // Loading dots cycle (manual timer so we can stop cleanly)
        let dotsT = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            DispatchQueue.main.async {
                guard isActive else { return }
                dotPulse = (dotPulse + 1) % 3
            }
        }
        timers.append(dotsT)
        
        // Build/sail loop
        runCycle(width: width)
    }
    
    private func runCycle(width: CGFloat) {
        guard isActive else { return }
        
        // Reset position
        sailX = 0
        sailY = -120
        phase = .idle
        
        // Drop into the wave with the hull
        withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
            sailY = 0
            phase = .hull
        }
        
        scheduleStep(after: 0.55) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                phase = .mast
            }
        }
        scheduleStep(after: 1.05) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
                phase = .sail
            }
        }
        scheduleStep(after: 1.65) {
            phase = .sailing
            // Sail across the screen
            withAnimation(.easeInOut(duration: 3.2)) {
                sailX = width / 2 + 80
            }
            // Gentle bobbing during the cruise
            withAnimation(.easeInOut(duration: 0.9).repeatCount(4, autoreverses: true)) {
                sailY = -8
            }
        }
        scheduleStep(after: 4.7) {
            withAnimation(.easeIn(duration: 0.4)) {
                phase = .gone
            }
        }
        scheduleStep(after: 5.2) {
            cycle += 1
            runCycle(width: width)
        }
    }
    
    private func scheduleStep(after seconds: TimeInterval, _ block: @escaping () -> Void) {
        let t = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in
            DispatchQueue.main.async {
                guard isActive else { return }
                block()
            }
        }
        timers.append(t)
    }
    
    private func stop() {
        isActive = false
        for t in timers { t.invalidate() }
        timers.removeAll()
    }
}

// MARK: - Wave Shape

struct WaveShape: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let midY = rect.height * 0.45
        p.move(to: CGPoint(x: 0, y: rect.height))
        p.addLine(to: CGPoint(x: 0, y: midY))

        let step: CGFloat = 2
        var x: CGFloat = 0
        while x <= rect.width {
            let relX = x / rect.width
            let y = midY + sin(relX * .pi * 2 * frequency + phase) * amplitude
            p.addLine(to: CGPoint(x: x, y: y))
            x += step
        }
        p.addLine(to: CGPoint(x: rect.width, y: rect.height))
        p.closeSubpath()
        return p
    }
}

// MARK: - Hull Shape (boat body)

struct HullShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: w, y: 0))
        p.addQuadCurve(
            to: CGPoint(x: w * 0.85, y: h),
            control: CGPoint(x: w * 1.0, y: h * 0.7)
        )
        p.addLine(to: CGPoint(x: w * 0.15, y: h))
        p.addQuadCurve(
            to: CGPoint(x: 0, y: 0),
            control: CGPoint(x: 0, y: h * 0.7)
        )
        return p
    }
}

// MARK: - Sail Shape (main sail, classic triangular)

struct SailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + 2, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + 2, y: rect.maxY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY * 0.5),
            control: CGPoint(x: rect.maxX * 0.85, y: rect.maxY * 0.95)
        )
        p.closeSubpath()
        return p
    }
}

// MARK: - Jib Shape (small front sail)

struct JibShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY * 0.95),
            control: CGPoint(x: rect.minX, y: rect.maxY * 0.6)
        )
        p.closeSubpath()
        return p
    }
}

// MARK: - Foam Layer

struct FoamLayer: View {
    let phase: CGFloat
    let active: Bool

    var body: some View {
        GeometryReader { geo in
            let count = 14
            ZStack {
                ForEach(0..<count, id: \.self) { i in
                    let progress = (CGFloat(i) / CGFloat(count) + phase / (.pi * 2))
                        .truncatingRemainder(dividingBy: 1)
                    let xPos = progress * geo.size.width
                    let bias = sin(progress * .pi)
                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 3 + CGFloat(i % 3), height: 3 + CGFloat(i % 3))
                        .offset(
                            x: xPos - geo.size.width / 2,
                            y: -bias * 6 + CGFloat((i % 5) - 2)
                        )
                        .blur(radius: 0.4)
                        .opacity(bias)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

// MARK: - Particle Field (ambient depth particles)

struct ParticleField: View {
    let active: Bool
    @State private var t: CGFloat = 0
    @State private var timer: Timer?

    private let particles: [Particle] = (0..<22).map { _ in Particle.random() }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles.indices, id: \.self) { i in
                    let p = particles[i]
                    let y = (p.y0 + t * p.speed).truncatingRemainder(dividingBy: 1.0)
                    Circle()
                        .fill(Color.white.opacity(p.alpha))
                        .frame(width: p.size, height: p.size)
                        .position(
                            x: p.x * geo.size.width + sin(t * 2 + p.x * 6) * 8,
                            y: (1 - y) * geo.size.height
                        )
                        .blur(radius: 0.3)
                }
            }
        }
        .onAppear { startTicking() }
        .onDisappear { stopTicking() }
        .onChange(of: active) { newValue in
            if newValue { startTicking() } else { stopTicking() }
        }
    }

    private func startTicking() {
        stopTicking()
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
            DispatchQueue.main.async {
                guard active else { return }
                t += 0.005
                if t > 100 { t = 0 }
            }
        }
        self.timer = timer
    }

    private func stopTicking() {
        timer?.invalidate()
        timer = nil
    }

    struct Particle {
        let x: CGFloat
        let y0: CGFloat
        let size: CGFloat
        let speed: CGFloat
        let alpha: Double

        static func random() -> Particle {
            Particle(
                x: .random(in: 0...1),
                y0: .random(in: 0...1),
                size: .random(in: 1.5...3.5),
                speed: .random(in: 0.05...0.18),
                alpha: .random(in: 0.15...0.55)
            )
        }
    }
}
