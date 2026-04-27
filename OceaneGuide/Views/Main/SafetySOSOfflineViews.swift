import SwiftUI

// MARK: - Safety Checklist View

struct SafetyChecklistView: View {
    @EnvironmentObject var checklistVM: ChecklistViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme

    @State private var showResetConfirm = false

    var body: some View {
        OGBackground {
            ScrollView {
                VStack(spacing: 18) {
                    progressCard
                    actionRow
                    ForEach(checklistVM.categoryOrder, id: \.self) { category in
                        categorySection(category)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
        }
        .navigationTitle("Safety Checklist")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showResetConfirm) {
            Alert(
                title: Text("Reset checklist?"),
                message: Text("All items will be unchecked."),
                primaryButton: .destructive(Text("Reset")) {
                    checklistVM.resetAll()
                    appState.notify(.warning)
                },
                secondaryButton: .cancel()
            )
        }
    }

    private var progressCard: some View {
        let pct = checklistVM.progress
        let done = checklistVM.items.filter { $0.isChecked }.count
        let total = checklistVM.items.count
        return OGCard {
            VStack(spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pre-departure")
                            .font(.ogCaption(12))
                            .foregroundColor(.secondary)
                        Text("\(done) of \(total) complete")
                            .font(.ogTitle(20))
                            .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.15), lineWidth: 6)
                            .frame(width: 56, height: 56)
                        Circle()
                            .trim(from: 0, to: CGFloat(pct))
                            .stroke(
                                pct == 1.0 ? OGTheme.success : OGTheme.ocean,
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 56, height: 56)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: pct)
                        Text("\(Int(pct * 100))%")
                            .font(.ogHeadline(13))
                            .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                    }
                }
                if pct == 1.0 {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(OGTheme.success)
                        Text("Ready to depart")
                            .font(.ogHeadline(13))
                            .foregroundColor(OGTheme.success)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(OGTheme.success.opacity(0.15)))
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            OGSecondaryButton(title: "Check All", icon: "checkmark.circle") {
                appState.haptic()
                checklistVM.checkAll()
            }
            OGGhostButton(title: "Reset", icon: "arrow.counterclockwise") {
                showResetConfirm = true
            }
        }
    }

    private func categorySection(_ category: String) -> some View {
        let progress = checklistVM.categoryProgress(category)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(category)
                    .font(.ogHeadline(15))
                    .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                Spacer()
                Text("\(progress.done)/\(progress.total)")
                    .font(.ogCaption(11))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(progress.done == progress.total ? OGTheme.success.opacity(0.18) : Color.gray.opacity(0.15)))
                    .foregroundColor(progress.done == progress.total ? OGTheme.success : .secondary)
            }
            .padding(.horizontal, 4)
            OGCard(padding: 0) {
                VStack(spacing: 0) {
                    let items = checklistVM.items(in: category)
                    ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                        Button {
                            appState.haptic(.light)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                checklistVM.toggle(item)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(item.isChecked ? OGTheme.success : Color.clear)
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 7)
                                                .stroke(item.isChecked ? OGTheme.success : Color.gray.opacity(0.4), lineWidth: 2)
                                        )
                                    if item.isChecked {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.ogHeadline(14))
                                        .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                                        .strikethrough(item.isChecked, color: .secondary)
                                    Text(item.detail)
                                        .font(.ogCaption(11))
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        if idx < items.count - 1 {
                            Divider().background(Color.gray.opacity(0.1))
                                .padding(.leading, 50)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - SOS View

struct SOSView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var notificationVM: NotificationViewModel
    @Environment(\.colorScheme) var scheme
    @Environment(\.presentationMode) var presentationMode

    @State private var armed = false
    @State private var countdown = 3
    @State private var triggered = false
    @State private var pulseAnim = false
    @State private var timer: Timer?

    private let position = (lat: 37.9839, lon: -0.6814) // Torrevieja-ish

    var body: some View {
        OGBackground {
            ScrollView {
                VStack(spacing: 18) {
                    if triggered {
                        triggeredCard
                    } else {
                        sosButton
                    }
                    positionCard
                    contactsCard
                    safetyTipsCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
        }
        .navigationTitle("Emergency")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                pulseAnim = true
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private var sosButton: some View {
        VStack(spacing: 14) {
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(OGTheme.danger.opacity(0.4 - Double(i) * 0.1), lineWidth: 3)
                        .frame(width: 200 + CGFloat(i * 30), height: 200 + CGFloat(i * 30))
                        .scaleEffect(pulseAnim ? 1.1 : 0.95)
                        .opacity(pulseAnim ? 0.3 : 0.8)
                }
                Button {
                    appState.notify(.error)
                    triggerSOS()
                } label: {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [OGTheme.danger, OGTheme.coral],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(width: 180, height: 180)
                            .shadow(color: OGTheme.danger.opacity(0.6), radius: 20, x: 0, y: 8)
                        VStack(spacing: 6) {
                            if armed {
                                Text("\(countdown)")
                                    .font(.system(size: 64, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Tap to cancel")
                                    .font(.ogCaption(12))
                                    .foregroundColor(.white.opacity(0.9))
                            } else {
                                Text("SOS")
                                    .font(.system(size: 56, weight: .heavy))
                                    .foregroundColor(.white)
                                Text("Hold for emergency")
                                    .font(.ogCaption(12))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(height: 280)
            Text(armed ? "Sending SOS in \(countdown)s..." : "Press to send distress signal")
                .font(.ogHeadline(14))
                .foregroundColor(armed ? OGTheme.danger : .secondary)
        }
    }

    private var triggeredCard: some View {
        OGCard {
            VStack(spacing: 14) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 44))
                    .foregroundColor(OGTheme.danger)
                Text("SOS Sent")
                    .font(.ogTitle(22))
                    .foregroundColor(OGTheme.danger)
                Text("Emergency contacts have been notified with your position. Stay calm and remain visible.")
                    .font(.ogBody(14))
                    .foregroundColor(scheme == .dark ? .white.opacity(0.9) : OGTheme.nightBlue.opacity(0.85))
                    .multilineTextAlignment(.center)
                OGSecondaryButton(title: "Cancel SOS", icon: "xmark.circle") {
                    triggered = false
                    appState.notify(.warning)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var positionCard: some View {
        OGCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .foregroundColor(OGTheme.ocean)
                    Text("Current Position")
                        .font(.ogHeadline(15))
                        .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                }
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Latitude").font(.ogCaption(11)).foregroundColor(.secondary)
                        Text(String(format: "%.4f° N", position.lat))
                            .font(.ogMono(15))
                            .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Longitude").font(.ogCaption(11)).foregroundColor(.secondary)
                        Text(String(format: "%.4f° W", abs(position.lon)))
                            .font(.ogMono(15))
                            .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                    }
                }
                HStack(spacing: 6) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("Position will be sent with SOS")
                        .font(.ogCaption(11))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var contactsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            OGSectionHeader(title: "Emergency Contacts")
            OGCard(padding: 0) {
                VStack(spacing: 0) {
                    contactRow(name: "Coast Guard", number: "112", icon: "shield.fill", color: OGTheme.danger)
                    Divider().background(Color.gray.opacity(0.1)).padding(.leading, 56)
                    contactRow(name: "Marine Rescue", number: "VHF Ch. 16", icon: "antenna.radiowaves.left.and.right", color: OGTheme.warning)
                    Divider().background(Color.gray.opacity(0.1)).padding(.leading, 56)
                    contactRow(name: "Harbor Master", number: "+34 965 71 00 00", icon: "phone.fill", color: OGTheme.ocean)
                }
            }
        }
    }

    private func contactRow(name: String, number: String, icon: String, color: Color) -> some View {
        Button {
            appState.haptic()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(color.opacity(0.15)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.ogHeadline(14))
                        .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                    Text(number)
                        .font(.ogCaption(12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "phone.arrow.up.right.fill")
                    .font(.system(size: 14))
                    .foregroundColor(OGTheme.ocean)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var safetyTipsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            OGSectionHeader(title: "While Awaiting Rescue")
            OGCard {
                VStack(alignment: .leading, spacing: 10) {
                    tipRow("1.", "Put on life jackets")
                    tipRow("2.", "Stay together near the vessel if it's afloat")
                    tipRow("3.", "Keep flares and signals ready to use")
                    tipRow("4.", "Conserve phone battery; only call when necessary")
                    tipRow("5.", "Stay calm and visible — wave brightly colored cloth")
                }
            }
        }
    }

    private func tipRow(_ num: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(num)
                .font(.ogHeadline(13))
                .foregroundColor(OGTheme.ocean)
                .frame(width: 18, alignment: .leading)
            Text(text)
                .font(.ogBody(14))
                .foregroundColor(scheme == .dark ? .white.opacity(0.9) : OGTheme.nightBlue.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func triggerSOS() {
        if armed {
            // Cancel
            armed = false
            countdown = 3
            timer?.invalidate()
            timer = nil
            return
        }
        armed = true
        countdown = 3
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            countdown -= 1
            appState.haptic()
            if countdown <= 0 {
                t.invalidate()
                self.timer = nil
                self.armed = false
                self.triggered = true
                let notif = AppNotification(
                    title: "SOS Sent",
                    body: String(format: "Distress signal sent at %.4f, %.4f", position.lat, position.lon),
                    symbol: "antenna.radiowaves.left.and.right"
                )
                self.notificationVM.add(notif)
                self.appState.notify(.error)
            }
        }
    }
}

// MARK: - Offline Maps View

struct OfflineMapsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme

    @State private var regions: [MapRegionItem] = MapRegionItem.seedRegions

    private var totalDownloadedMB: Int {
        regions.filter { $0.isDownloaded }.reduce(0) { $0 + $1.sizeMB }
    }

    var body: some View {
        OGBackground {
            ScrollView {
                VStack(spacing: 18) {
                    storageCard
                    enabledToggleCard
                    VStack(alignment: .leading, spacing: 10) {
                        OGSectionHeader(title: "Regions", subtitle: "Tap to download or remove")
                        VStack(spacing: 10) {
                            ForEach($regions) { $region in
                                regionRow(region: $region)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
        }
        .navigationTitle("Offline Maps")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var storageCard: some View {
        let downloaded = regions.filter { $0.isDownloaded }.reduce(0) { $0 + $1.sizeMB }
        let pct = min(1.0, Double(downloaded) / 2000.0) // 2 GB cap visualization
        return OGCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Storage Used")
                            .font(.ogCaption(12))
                            .foregroundColor(.secondary)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(downloaded)")
                                .font(.ogTitle(26))
                                .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                            Text("MB")
                                .font(.ogCaption(12))
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "externaldrive.fill")
                        .font(.system(size: 30))
                        .foregroundColor(OGTheme.ocean)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.gray.opacity(0.15))
                        Capsule()
                            .fill(OGTheme.oceanGradient)
                            .frame(width: geo.size.width * CGFloat(pct))
                    }
                }
                .frame(height: 8)
                Text("\(regions.filter { $0.isDownloaded }.count) of \(regions.count) regions downloaded")
                    .font(.ogCaption(11))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var enabledToggleCard: some View {
        OGCard(padding: 14) {
            HStack(spacing: 12) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(OGTheme.ocean)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(OGTheme.ocean.opacity(0.15)))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Use offline maps")
                        .font(.ogHeadline(14))
                        .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                    Text("Required when out of cellular range")
                        .font(.ogCaption(11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: $appState.offlineMapsEnabled)
                    .labelsHidden()
                    .tint(OGTheme.ocean)
            }
        }
    }

    private func regionRow(region: Binding<MapRegionItem>) -> some View {
        let r = region.wrappedValue
        return OGCard(padding: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(r.isDownloaded ? OGTheme.success.opacity(0.15) : OGTheme.ocean.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: r.isDownloaded ? "checkmark.circle.fill" : "map.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(r.isDownloaded ? OGTheme.success : OGTheme.ocean)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(r.name)
                        .font(.ogHeadline(15))
                        .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                    HStack(spacing: 6) {
                        Text(r.detail)
                            .font(.ogCaption(11))
                            .foregroundColor(.secondary)
                        Text("·")
                            .font(.ogCaption(11))
                            .foregroundColor(.secondary)
                        Text("\(r.sizeMB) MB")
                            .font(.ogCaption(11))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if r.isDownloading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: OGTheme.ocean))
                } else {
                    Button {
                        appState.haptic()
                        if r.isDownloaded {
                            region.wrappedValue.isDownloaded = false
                        } else {
                            startDownload(region: region)
                        }
                    } label: {
                        Image(systemName: r.isDownloaded ? "trash" : "arrow.down.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(r.isDownloaded ? OGTheme.coral : OGTheme.ocean)
                    }
                }
            }
        }
    }

    private func startDownload(region: Binding<MapRegionItem>) {
        region.wrappedValue.isDownloading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            region.wrappedValue.isDownloading = false
            region.wrappedValue.isDownloaded = true
            appState.notify(.success)
        }
    }
}

struct MapRegionItem: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let sizeMB: Int
    var isDownloaded: Bool
    var isDownloading: Bool = false

    static var seedRegions: [MapRegionItem] {
        [
            MapRegionItem(name: "Mediterranean West", detail: "Spain, France, Italy", sizeMB: 420, isDownloaded: true),
            MapRegionItem(name: "Balearic Islands", detail: "Mallorca, Ibiza, Menorca", sizeMB: 120, isDownloaded: true),
            MapRegionItem(name: "Costa Blanca", detail: "Alicante, Valencia coast", sizeMB: 85, isDownloaded: false),
            MapRegionItem(name: "Costa del Sol", detail: "Málaga, Marbella", sizeMB: 95, isDownloaded: false),
            MapRegionItem(name: "Adriatic Sea", detail: "Croatia, Italy east", sizeMB: 280, isDownloaded: false),
            MapRegionItem(name: "Aegean Sea", detail: "Greece, Turkey west", sizeMB: 310, isDownloaded: false),
            MapRegionItem(name: "English Channel", detail: "UK & France", sizeMB: 220, isDownloaded: false),
            MapRegionItem(name: "Baltic Sea", detail: "Northern Europe", sizeMB: 380, isDownloaded: false)
        ]
    }
}
