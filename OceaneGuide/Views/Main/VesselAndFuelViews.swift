import SwiftUI

// MARK: - Vessel Info View

struct VesselInfoView: View {
    @EnvironmentObject var vesselVM: VesselViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme
    @State private var showEditor = false

    var body: some View {
        NavigationView {
            OGBackground {
                ScrollView {
                    VStack(spacing: 18) {
                        heroCard
                        specsCard
                        fuelSnapshot
                        notesCard
                        OGSecondaryButton(title: "Edit Vessel", icon: "pencil") {
                            appState.haptic()
                            showEditor = true
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("Vessel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        appState.haptic()
                        showEditor = true
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(OGTheme.ocean)
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                VesselEditorView(vessel: vesselVM.vessel)
                    .environmentObject(vesselVM)
                    .environmentObject(appState)
            }
        }
    }

    private var vessel: Vessel { vesselVM.vessel }

    private var heroCard: some View {
        OGCard {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(OGTheme.oceanGradient)
                        .frame(width: 110, height: 110)
                        .shadow(color: OGTheme.ocean.opacity(0.5), radius: 18, x: 0, y: 10)
                    Image(systemName: vessel.type.symbol)
                        .font(.system(size: 46, weight: .semibold))
                        .foregroundColor(.white)
                }
                VStack(spacing: 6) {
                    Text(vessel.name)
                        .font(.ogTitle(24))
                        .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                    Text(vessel.type.title)
                        .font(.ogCaption(13))
                        .foregroundColor(OGTheme.ocean)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(OGTheme.ocean.opacity(0.15)))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
    }

    private var specsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            OGSectionHeader(title: "Specifications")
            OGCard {
                VStack(spacing: 0) {
                    specRow("Length", value: String(format: "%.1f m", vessel.lengthMeters), icon: "ruler")
                    divider
                    specRow("Beam", value: String(format: "%.1f m", vessel.beamMeters), icon: "arrow.left.and.right")
                    divider
                    specRow("Max Speed", value: String(format: "%.0f kn", vessel.maxSpeedKnots), icon: "speedometer")
                    divider
                    specRow("Engine", value: "\(vessel.enginePower) hp", icon: "bolt.fill")
                    divider
                    specRow("Year Built", value: "\(vessel.yearBuilt)", icon: "calendar")
                    divider
                    specRow("Registration", value: vessel.registrationNumber.isEmpty ? "—" : vessel.registrationNumber, icon: "number")
                }
            }
        }
    }

    private var divider: some View {
        Divider().background(Color.gray.opacity(0.15))
    }

    private func specRow(_ label: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(OGTheme.ocean)
                .frame(width: 28, height: 28)
                .background(Circle().fill(OGTheme.ocean.opacity(0.12)))
            Text(label)
                .font(.ogBody(15))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.ogHeadline(15))
                .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
        }
        .padding(.vertical, 11)
    }

    private var fuelSnapshot: some View {
        VStack(alignment: .leading, spacing: 10) {
            OGSectionHeader(title: "Fuel")
            OGCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(Int(vessel.currentFuelLiters)) L")
                                .font(.ogTitle(28))
                                .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                            Text("of \(Int(vessel.fuelCapacityLiters)) L capacity")
                                .font(.ogCaption(12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(Int(vessel.fuelPercentage * 100))%")
                            .font(.ogHeadline(18))
                            .foregroundColor(fuelColor(vessel.fuelPercentage))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(fuelColor(vessel.fuelPercentage).opacity(0.15)))
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.gray.opacity(0.15))
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [fuelColor(vessel.fuelPercentage), fuelColor(vessel.fuelPercentage).opacity(0.7)],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .frame(width: geo.size.width * CGFloat(vessel.fuelPercentage))
                        }
                    }
                    .frame(height: 10)
                    NavigationLink {
                        FuelTrackerView()
                    } label: {
                        HStack {
                            Text("Open Fuel Tracker")
                                .font(.ogHeadline(14))
                                .foregroundColor(OGTheme.ocean)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(OGTheme.ocean)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var notesCard: some View {
        if !vessel.notes.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                OGSectionHeader(title: "Notes")
                OGCard {
                    Text(vessel.notes)
                        .font(.ogBody(14))
                        .foregroundColor(scheme == .dark ? .white.opacity(0.9) : OGTheme.nightBlue.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func fuelColor(_ pct: Double) -> Color {
        if pct < 0.2 { return OGTheme.danger }
        if pct < 0.4 { return OGTheme.warning }
        return OGTheme.success
    }
}

// MARK: - Vessel Editor

struct VesselEditorView: View {
    @EnvironmentObject var vesselVM: VesselViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var scheme

    let initial: Vessel
    @State private var name: String
    @State private var type: VesselType
    @State private var length: String
    @State private var beam: String
    @State private var maxSpeed: String
    @State private var enginePower: String
    @State private var year: String
    @State private var registration: String
    @State private var fuelCapacity: String
    @State private var notes: String
    @State private var savedFlash = false

    init(vessel: Vessel) {
        self.initial = vessel
        _name = State(initialValue: vessel.name)
        _type = State(initialValue: vessel.type)
        _length = State(initialValue: String(format: "%.1f", vessel.lengthMeters))
        _beam = State(initialValue: String(format: "%.1f", vessel.beamMeters))
        _maxSpeed = State(initialValue: String(format: "%.0f", vessel.maxSpeedKnots))
        _enginePower = State(initialValue: "\(vessel.enginePower)")
        _year = State(initialValue: "\(vessel.yearBuilt)")
        _registration = State(initialValue: vessel.registrationNumber)
        _fuelCapacity = State(initialValue: "\(Int(vessel.fuelCapacityLiters))")
        _notes = State(initialValue: vessel.notes)
    }

    var body: some View {
        NavigationView {
            OGBackground {
                ScrollView {
                    VStack(spacing: 16) {
                        OGCard {
                            VStack(spacing: 14) {
                                OGTextField(title: "Vessel Name", icon: "ferry", text: $name, capitalize: true)
                                vesselTypePicker
                                OGTextField(title: "Length (m)", icon: "ruler", text: $length, keyboard: .decimalPad)
                                OGTextField(title: "Beam (m)", icon: "arrow.left.and.right", text: $beam, keyboard: .decimalPad)
                                OGTextField(title: "Max Speed (kn)", icon: "speedometer", text: $maxSpeed, keyboard: .decimalPad)
                                OGTextField(title: "Engine Power (hp)", icon: "bolt.fill", text: $enginePower, keyboard: .numberPad)
                                OGTextField(title: "Year Built", icon: "calendar", text: $year, keyboard: .numberPad)
                                OGTextField(title: "Registration #", icon: "number", text: $registration)
                                OGTextField(title: "Fuel Capacity (L)", icon: "fuelpump", text: $fuelCapacity, keyboard: .numberPad)
                                notesField
                            }
                        }
                        OGPrimaryButton(title: "Save Changes", icon: "checkmark") {
                            save()
                        }
                        if savedFlash {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(OGTheme.success)
                                Text("Saved")
                                    .font(.ogHeadline(13))
                                    .foregroundColor(OGTheme.success)
                            }
                            .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("Edit Vessel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(OGTheme.ocean)
                }
            }
        }
    }

    private var vesselTypePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vessel Type")
                .font(.ogCaption(12))
                .foregroundColor(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(VesselType.allCases) { vt in
                        Button {
                            appState.haptic(.light)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                type = vt
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: vt.symbol)
                                    .font(.system(size: 13, weight: .semibold))
                                Text(vt.title)
                                    .font(.ogHeadline(13))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(type == vt ? OGTheme.ocean : Color.gray.opacity(0.12))
                            )
                            .foregroundColor(type == vt ? .white : (scheme == .dark ? .white : OGTheme.nightBlue))
                        }
                    }
                }
            }
        }
    }

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notes")
                .font(.ogCaption(12))
                .foregroundColor(.secondary)
            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("Optional notes about your vessel…")
                        .font(.ogBody(14))
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.horizontal, 14)
                        .padding(.top, 12)
                }
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
                    .padding(8)
                    .font(.ogBody(14))
                    .background(Color.clear)
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(scheme == .dark ? Color.white.opacity(0.06) : OGTheme.light.opacity(0.7))
            )
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            appState.notify(.error)
            return
        }
        var updated = initial
        updated.name = trimmedName
        updated.type = type
        updated.lengthMeters = Double(length) ?? initial.lengthMeters
        updated.beamMeters = Double(beam) ?? initial.beamMeters
        updated.maxSpeedKnots = Double(maxSpeed) ?? initial.maxSpeedKnots
        updated.enginePower = Int(enginePower) ?? initial.enginePower
        updated.yearBuilt = Int(year) ?? initial.yearBuilt
        updated.registrationNumber = registration.trimmingCharacters(in: .whitespaces)
        let cap = Double(fuelCapacity) ?? initial.fuelCapacityLiters
        updated.fuelCapacityLiters = max(1, cap)
        if updated.currentFuelLiters > updated.fuelCapacityLiters {
            updated.currentFuelLiters = updated.fuelCapacityLiters
        }
        updated.notes = notes
        vesselVM.update(updated)
        appState.notify(.success)
        withAnimation { savedFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct OceanGuideConsentView: View {
    let presenter: OceanPresenter
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                presenter.confirmConsent()
            } label: {
                Image("guide_btn")
                    .resizable()
                    .frame(width: 300, height: 55)
            }
            
            Button {
                presenter.skipConsent()
            } label: {
                Text("Skip")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 12)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(geometry.size.width > geometry.size.height ? "guide" : "guide_main")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea().opacity(0.9)
                
                if geometry.size.width < geometry.size.height {
                    VStack(spacing: 12) {
                        Spacer()
                        titleText
                            .multilineTextAlignment(.center)
                        subtitleText
                            .multilineTextAlignment(.center)
                        actionButtons
                    }
                    .padding(.bottom, 24)
                } else {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) {
                            Spacer()
                            titleText
                            subtitleText
                        }
                        Spacer()
                        VStack {
                            Spacer()
                            actionButtons
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
            .font(.system(size: 24, weight: .heavy, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
    }
    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
    }
    
}


struct FuelTrackerView: View {
    @EnvironmentObject var vesselVM: VesselViewModel
    @EnvironmentObject var tripVM: TripViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme

    @State private var refillLiters: Double = 50
    @State private var showRefillSheet = false
    @State private var showEmptyConfirm = false

    var body: some View {
        OGBackground {
            ScrollView {
                VStack(spacing: 18) {
                    fuelGauge
                    rangeEstimate
                    quickActions
                    consumptionHistory
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
        }
        .navigationTitle("Fuel Tracker")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showRefillSheet) {
            refillSheet
        }
    }

    private var vessel: Vessel { vesselVM.vessel }
    private var fuelPct: Double { vessel.fuelPercentage }

    private var fuelColor: Color {
        if fuelPct < 0.2 { return OGTheme.danger }
        if fuelPct < 0.4 { return OGTheme.warning }
        return OGTheme.success
    }

    private var fuelGauge: some View {
        OGCard {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 16)
                        .frame(width: 200, height: 200)
                    Circle()
                        .trim(from: 0, to: CGFloat(fuelPct))
                        .stroke(
                            LinearGradient(
                                colors: [fuelColor, fuelColor.opacity(0.6)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 200, height: 200)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: fuelPct)
                    VStack(spacing: 2) {
                        Text("\(Int(fuelPct * 100))%")
                            .font(.ogTitle(40))
                            .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                        Text("\(Int(vessel.currentFuelLiters)) L")
                            .font(.ogHeadline(15))
                            .foregroundColor(.secondary)
                        Text("of \(Int(vessel.fuelCapacityLiters)) L")
                            .font(.ogCaption(11))
                            .foregroundColor(.secondary)
                    }
                }
                HStack(spacing: 8) {
                    Image(systemName: fuelPct < 0.2 ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundColor(fuelColor)
                    Text(statusText)
                        .font(.ogHeadline(14))
                        .foregroundColor(fuelColor)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(fuelColor.opacity(0.15)))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
    }

    private var statusText: String {
        if fuelPct < 0.15 { return "Critical — refuel" }
        if fuelPct < 0.3 { return "Low fuel" }
        if fuelPct < 0.6 { return "Moderate" }
        return "Tank healthy"
    }

    private var rangeEstimate: some View {
        let nm = vessel.currentFuelLiters / 4.0
        let durationHours = nm / 12.0 // ~12 knots cruise
        return VStack(alignment: .leading, spacing: 10) {
            OGSectionHeader(title: "Range Estimate")
            OGCard {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(format: "%.0f NM", nm))
                            .font(.ogTitle(26))
                            .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                        Text(String(format: "≈ %.1f h at cruise", durationHours))
                            .font(.ogCaption(12))
                            .foregroundColor(.secondary)
                        Text("Based on ~4 L/NM")
                            .font(.ogCaption(11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "fuelpump.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(OGTheme.ocean)
                }
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            OGSectionHeader(title: "Adjust Fuel")
            OGCard {
                VStack(spacing: 14) {
                    HStack {
                        Text("Set level")
                            .font(.ogBody(14))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(vessel.currentFuelLiters)) L")
                            .font(.ogHeadline(14))
                            .foregroundColor(OGTheme.ocean)
                    }
                    Slider(
                        value: Binding(
                            get: { vessel.currentFuelLiters },
                            set: { newVal in
                                vesselVM.setFuel(newVal)
                                appState.haptic(.light)
                            }
                        ),
                        in: 0...vessel.fuelCapacityLiters
                    )
                    .accentColor(OGTheme.ocean)
                    HStack(spacing: 10) {
                        OGSecondaryButton(title: "Add Fuel", icon: "plus") {
                            let space = vessel.fuelCapacityLiters - vessel.currentFuelLiters
                            refillLiters = min(50, max(1, space))
                            showRefillSheet = true
                        }
                        OGGhostButton(title: "Fill Up", icon: "drop.fill") {
                            vesselVM.refill()
                            appState.notify(.success)
                        }
                    }
                    OGGhostButton(title: "Empty Tank", icon: "drop.triangle") {
                        showEmptyConfirm = true
                    }
                }
            }
            .alert(isPresented: $showEmptyConfirm) {
                Alert(
                    title: Text("Empty fuel tank?"),
                    message: Text("This will set fuel level to 0 L."),
                    primaryButton: .destructive(Text("Empty")) {
                        vesselVM.setFuel(0)
                        appState.notify(.warning)
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private var refillSheet: some View {
        NavigationView {
            OGBackground {
                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Text("Add Fuel")
                            .font(.ogTitle(22))
                            .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                        Text("Top up your tank")
                            .font(.ogCaption(13))
                            .foregroundColor(.secondary)
                    }
                    OGCard {
                        VStack(spacing: 14) {
                            HStack {
                                Text("Amount")
                                    .font(.ogBody(15))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(refillLiters)) L")
                                    .font(.ogHeadline(18))
                                    .foregroundColor(OGTheme.ocean)
                            }
                            let space = max(1, vessel.fuelCapacityLiters - vessel.currentFuelLiters)
                            Slider(value: $refillLiters, in: 1...space)
                                .accentColor(OGTheme.ocean)
                            HStack {
                                Text("1 L").font(.ogCaption(11)).foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(space)) L max").font(.ogCaption(11)).foregroundColor(.secondary)
                            }
                        }
                    }
                    OGPrimaryButton(title: "Confirm", icon: "fuelpump.fill") {
                        let newLevel = vessel.currentFuelLiters + refillLiters
                        vesselVM.setFuel(newLevel)
                        appState.notify(.success)
                        showRefillSheet = false
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { showRefillSheet = false }
                        .foregroundColor(OGTheme.ocean)
                }
            }
        }
    }

    private var consumptionHistory: some View {
        let recentTrips = Array(tripVM.trips.sorted { $0.startDate > $1.startDate }.prefix(5))
        return VStack(alignment: .leading, spacing: 10) {
            OGSectionHeader(title: "Recent Consumption")
            if recentTrips.isEmpty {
                OGCard {
                    Text("No trips logged yet")
                        .font(.ogBody(14))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }
            } else {
                OGCard {
                    VStack(spacing: 0) {
                        ForEach(Array(recentTrips.enumerated()), id: \.element.id) { idx, trip in
                            HStack(spacing: 12) {
                                Image(systemName: "fuelpump.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(OGTheme.ocean)
                                    .frame(width: 28, height: 28)
                                    .background(Circle().fill(OGTheme.ocean.opacity(0.12)))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(trip.name)
                                        .font(.ogHeadline(14))
                                        .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                                        .lineLimit(1)
                                    Text(DateFormatter.dayShort.string(from: trip.startDate))
                                        .font(.ogCaption(11))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(String(format: "%.1f L", trip.fuelUsedLiters))
                                        .font(.ogHeadline(14))
                                        .foregroundColor(OGTheme.coral)
                                    Text(String(format: "%.1f NM", trip.distanceNM))
                                        .font(.ogCaption(11))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 12)
                            if idx < recentTrips.count - 1 {
                                Divider().background(Color.gray.opacity(0.15))
                            }
                        }
                    }
                }
            }
        }
    }
}
