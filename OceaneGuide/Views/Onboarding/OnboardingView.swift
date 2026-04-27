import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var page: Int = 0

    private let pages: [OnboardingPage] = [
        .init(title: "Navigate with Confidence",
              subtitle: "Real-time position, heading, and speed — your sea command center.",
              symbol: "location.north.line.fill",
              accent: OGTheme.ocean,
              illustration: .compass),
        .init(title: "Plan Your Journey",
              subtitle: "Build smart routes, drop waypoints, estimate time and fuel.",
              symbol: "map.fill",
              accent: OGTheme.depth,
              illustration: .map),
        .init(title: "Stay Safe at Sea",
              subtitle: "Weather alerts, safety checklists, and a one-tap SOS — always ready.",
              symbol: "shield.lefthalf.filled",
              accent: OGTheme.coral,
              illustration: .shield)
    ]

    var body: some View {
        OGBackground {
            VStack(spacing: 0) {
                // Skip
                HStack {
                    Spacer()
                    Button("Skip") { complete() }
                        .font(.ogHeadline(15))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 22)
                        .padding(.top, 12)
                }

                TabView(selection: $page) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        OnboardingPageView(page: pages[i])
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: page)

                // Indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? OGTheme.ocean : OGTheme.ocean.opacity(0.25))
                            .frame(width: i == page ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: page)
                    }
                }
                .padding(.bottom, 24)

                // CTA
                HStack(spacing: 12) {
                    if page > 0 {
                        OGSecondaryButton(title: "Back", icon: "chevron.left") {
                            withAnimation { page -= 1 }
                            appState.haptic(.light)
                        }
                    }
                    OGPrimaryButton(
                        title: page == pages.count - 1 ? "Get Started" : "Next",
                        icon: page == pages.count - 1 ? "checkmark" : "chevron.right"
                    ) {
                        appState.haptic(.medium)
                        if page == pages.count - 1 {
                            complete()
                        } else {
                            withAnimation { page += 1 }
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 28)
            }
        }
    }

    private func complete() {
        withAnimation(.easeInOut(duration: 0.4)) {
            appState.hasCompletedOnboarding = true
        }
    }
}

struct OnboardingPage: Identifiable {
    enum Illustration { case compass, map, shield }
    let id = UUID()
    let title: String
    let subtitle: String
    let symbol: String
    let accent: Color
    let illustration: Illustration
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var animate = false
    @State private var rotateNeedle: Double = 0

    var body: some View {
        VStack(spacing: 30) {
            illustrationView
                .frame(height: 320)
                .padding(.top, 20)

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.ogTitle(30))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Text(page.subtitle)
                    .font(.ogBody(16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) { animate = true }
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                rotateNeedle = 360
            }
        }
        .onDisappear { animate = false }
    }

    @ViewBuilder
    private var illustrationView: some View {
        ZStack {
            // Backdrop circle
            Circle()
                .fill(LinearGradient(colors: [page.accent.opacity(0.18), page.accent.opacity(0.05)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 280, height: 280)

            Circle()
                .stroke(page.accent.opacity(0.25), lineWidth: 1)
                .frame(width: 240, height: 240)

            switch page.illustration {
            case .compass:
                compassIllustration
            case .map:
                mapIllustration
            case .shield:
                shieldIllustration
            }
        }
        .scaleEffect(animate ? 1 : 0.85)
        .opacity(animate ? 1 : 0)
    }

    private var compassIllustration: some View {
        ZStack {
            Circle()
                .stroke(OGTheme.depth.opacity(0.4), lineWidth: 2)
                .frame(width: 180, height: 180)
            ForEach(0..<12) { i in
                Capsule()
                    .fill(OGTheme.depth.opacity(0.6))
                    .frame(width: 2, height: i % 3 == 0 ? 14 : 8)
                    .offset(y: -90)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
            // Needle
            Capsule()
                .fill(LinearGradient(colors: [OGTheme.coral, OGTheme.danger],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 6, height: 100)
                .offset(y: -30)
            Capsule()
                .fill(LinearGradient(colors: [OGTheme.depth, OGTheme.nightBlue],
                                     startPoint: .bottom, endPoint: .top))
                .frame(width: 6, height: 60)
                .offset(y: 30)
            Circle().fill(OGTheme.nightBlue).frame(width: 14, height: 14)

            Image(systemName: page.symbol)
                .font(.system(size: 80, weight: .heavy))
                .foregroundColor(.white)
                .opacity(0)
        }
        .rotationEffect(.degrees(rotateNeedle))
    }

    private var mapIllustration: some View {
        ZStack {
            // Stylized map grid
            RoundedRectangle(cornerRadius: 22)
                .fill(OGTheme.depth.opacity(0.15))
                .frame(width: 220, height: 180)

            Path { p in
                p.move(to: CGPoint(x: 20, y: 130))
                p.addCurve(to: CGPoint(x: 200, y: 50),
                           control1: CGPoint(x: 80, y: 100),
                           control2: CGPoint(x: 130, y: 160))
            }
            .stroke(OGTheme.ocean, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [10, 6]))
            .frame(width: 220, height: 180)

            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(OGTheme.coral)
                    .font(.system(size: 28))
                    .offset(x: -90, y: 30)
                Image(systemName: "flag.checkered.circle.fill")
                    .foregroundColor(OGTheme.success)
                    .font(.system(size: 30))
                    .offset(x: 80, y: -50)
            }

            Image(systemName: "sailboat.fill")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(OGTheme.depth)
                .offset(x: 0, y: 0)
        }
    }

    private var shieldIllustration: some View {
        ZStack {
            Image(systemName: "shield.fill")
                .font(.system(size: 180, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [OGTheme.coral, OGTheme.danger.opacity(0.7)],
                                                 startPoint: .top, endPoint: .bottom))
            Image(systemName: "checkmark")
                .font(.system(size: 70, weight: .black))
                .foregroundColor(.white)
            // Pulse rings
            ForEach(0..<3) { i in
                Circle()
                    .stroke(page.accent.opacity(0.3 - Double(i) * 0.08), lineWidth: 2)
                    .frame(width: 200 + CGFloat(i * 30), height: 200 + CGFloat(i * 30))
                    .scaleEffect(animate ? 1.05 : 1)
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(Double(i) * 0.3), value: animate)
            }
        }
    }
}
