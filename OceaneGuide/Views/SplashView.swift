import SwiftUI

struct SplashView: View {
    @EnvironmentObject var appState: AppState
    @State private var waveOffset: CGFloat = 0
    @State private var logoScale: CGFloat = 0.4
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0
    @State private var particles: [SplashParticle] = (0..<14).map { _ in SplashParticle() }

    var body: some View {
        ZStack {
            // Deep ocean gradient
            LinearGradient(colors: [OGTheme.midnight, OGTheme.depth, OGTheme.ocean],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            // Animated wave layers
            WaveShape(offset: waveOffset, amplitude: 18, frequency: 1.6)
                .fill(OGTheme.light.opacity(0.18))
                .frame(height: 220)
                .offset(y: 200)

            WaveShape(offset: waveOffset * 1.4, amplitude: 14, frequency: 2.2)
                .fill(OGTheme.foam.opacity(0.10))
                .frame(height: 220)
                .offset(y: 240)

            // Particles
            ForEach(particles) { p in
                Circle()
                    .fill(Color.white.opacity(p.alpha))
                    .frame(width: p.size, height: p.size)
                    .offset(x: p.x, y: p.y)
            }

            VStack(spacing: 22) {
                // Logo
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)
                        .frame(width: 180, height: 180)

                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        .scaleEffect(ringScale * 1.15)
                        .opacity(ringOpacity * 0.7)
                        .frame(width: 220, height: 220)

                    Circle()
                        .fill(LinearGradient(colors: [OGTheme.foam, OGTheme.light],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 130, height: 130)
                        .shadow(color: .white.opacity(0.4), radius: 30)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                    Image(systemName: "sailboat.fill")
                        .font(.system(size: 56, weight: .black))
                        .foregroundStyle(LinearGradient(colors: [OGTheme.depth, OGTheme.nightBlue],
                                                        startPoint: .top, endPoint: .bottom))
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                VStack(spacing: 6) {
                    Text("Ocean Guide")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("Navigate with confidence")
                        .font(.ogBody(15))
                        .foregroundColor(.white.opacity(0.85))
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)
            }
        }
        .onAppear { runAnimations() }
    }

    private func runAnimations() {
        withAnimation(.linear(duration: 5.5).repeatForever(autoreverses: false)) {
            waveOffset = 360
        }

        withAnimation(.spring(response: 0.7, dampingFraction: 0.55).delay(0.15)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 1.2).delay(0.4)) {
            ringScale = 1.0
            ringOpacity = 1.0
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6)) {
            titleOffset = 0
            titleOpacity = 1
        }

        // Animate particles
        for i in particles.indices {
            withAnimation(.easeInOut(duration: Double.random(in: 2.5...4.5)).repeatForever(autoreverses: true)) {
                particles[i].x += CGFloat.random(in: -40...40)
                particles[i].y += CGFloat.random(in: -50...50)
                particles[i].alpha = Double.random(in: 0.1...0.5)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
            withAnimation(.easeInOut(duration: 0.4)) {
                appState.didLaunch = true
            }
        }
    }
}

struct SplashParticle: Identifiable {
    let id = UUID()
    var x: CGFloat = CGFloat.random(in: -180...180)
    var y: CGFloat = CGFloat.random(in: -380...380)
    var size: CGFloat = CGFloat.random(in: 2...5)
    var alpha: Double = Double.random(in: 0.1...0.4)
}

struct WaveShape: Shape {
    var offset: CGFloat
    var amplitude: CGFloat
    var frequency: CGFloat

    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        path.move(to: CGPoint(x: 0, y: midY))
        for x in stride(from: 0, through: rect.width, by: 2) {
            let relativeX = x / rect.width
            let sine = sin((relativeX * frequency + offset / 60) * .pi * 2)
            let y = midY + sine * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}
