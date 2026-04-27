import SwiftUI

// MARK: - Trip Log View

struct TripLogView: View {
    @EnvironmentObject var tripVM: TripViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme

    @State private var selectedTrip: Trip? = nil
    @State private var deletingTrip: Trip? = nil

    var body: some View {
        OGBackground {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCard
                    if tripVM.trips.isEmpty {
                        emptyState
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            OGSectionHeader(title: "All Trips", subtitle: "\(tripVM.trips.count) total")
                            VStack(spacing: 10) {
                                ForEach(sortedTrips) { trip in
                                    Button {
                                        appState.haptic(.light)
                                        selectedTrip = trip
                                    } label: {
                                        TripRow(trip: trip)
                                    }
                                    .contextMenu {
                                        Button {
                                            selectedTrip = trip
                                        } label: { Label("View Details", systemImage: "info.circle") }
                                        Button(role: .destructive) {
                                            deletingTrip = trip
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
        }
        .navigationTitle("Trip Log")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedTrip) { trip in
            TripDetailView(trip: trip)
                .environmentObject(tripVM)
                .environmentObject(appState)
        }
        .alert(item: $deletingTrip) { trip in
            Alert(
                title: Text("Delete trip?"),
                message: Text("\(trip.name) will be removed."),
                primaryButton: .destructive(Text("Delete")) {
                    tripVM.deleteTrip(trip)
                    appState.notify(.warning)
                },
                secondaryButton: .cancel()
            )
        }
    }

    private var sortedTrips: [Trip] {
        tripVM.trips.sorted { $0.startDate > $1.startDate }
    }

    private var summaryCard: some View {
        let totalNM = tripVM.trips.reduce(0) { $0 + $1.distanceNM }
        let totalFuel = tripVM.trips.reduce(0) { $0 + $1.fuelUsedLiters }
        let totalHours = tripVM.trips.reduce(0.0) { $0 + ($1.duration / 3600) }
        return OGCard {
            HStack(spacing: 0) {
                summaryStat(value: String(format: "%.1f", totalNM), unit: "NM", label: "Distance", icon: "map")
                Divider().frame(height: 40).background(Color.gray.opacity(0.15))
                summaryStat(value: String(format: "%.1f", totalHours), unit: "h", label: "Time", icon: "clock")
                Divider().frame(height: 40).background(Color.gray.opacity(0.15))
                summaryStat(value: "\(Int(totalFuel))", unit: "L", label: "Fuel", icon: "fuelpump")
            }
        }
    }

    private func summaryStat(value: String, unit: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(OGTheme.ocean)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.ogTitle(20))
                    .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                Text(unit)
                    .font(.ogCaption(11))
                    .foregroundColor(.secondary)
            }
            Text(label)
                .font(.ogCaption(11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(OGTheme.ocean)
            Text("No trips yet")
                .font(.ogHeadline(17))
                .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
            Text("Start tracking from the Bridge to log your journeys.")
                .font(.ogCaption(13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .padding(.top, 60)
    }
}

// MARK: - Trip Row

struct TripRow: View {
    let trip: Trip
    @Environment(\.colorScheme) var scheme

    var body: some View {
        OGCard(padding: 14) {
            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text(dayString)
                        .font(.ogHeadline(17))
                        .foregroundColor(.white)
                    Text(monthString)
                        .font(.ogCaption(10))
                        .foregroundColor(.white.opacity(0.85))
                }
                .frame(width: 50, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(OGTheme.oceanGradient)
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.name)
                        .font(.ogHeadline(15))
                        .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                        .lineLimit(1)
                    HStack(spacing: 10) {
                        statBadge(icon: "map", value: String(format: "%.1f NM", trip.distanceNM))
                        statBadge(icon: "speedometer", value: String(format: "%.1f kn", trip.avgSpeedKnots))
                    }
                    HStack(spacing: 10) {
                        statBadge(icon: "clock", value: trip.durationFormatted)
                        statBadge(icon: "fuelpump", value: String(format: "%.1f L", trip.fuelUsedLiters))
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func statBadge(icon: String, value: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(OGTheme.ocean)
            Text(value)
                .font(.ogCaption(11))
                .foregroundColor(.secondary)
        }
    }

    private var dayString: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: trip.startDate)
    }

    private var monthString: String {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f.string(from: trip.startDate).uppercased()
    }
}

// MARK: - Trip Detail

struct TripDetailView: View {
    let trip: Trip
    @EnvironmentObject var tripVM: TripViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var scheme

    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationView {
            OGBackground {
                ScrollView {
                    VStack(spacing: 18) {
                        header
                        statsGrid
                        timingCard
                        if !trip.notes.isEmpty {
                            notesCard
                        }
                        OGGhostButton(title: "Delete Trip", icon: "trash") {
                            showDeleteConfirm = true
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("Trip Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(OGTheme.ocean)
                }
            }
            .alert(isPresented: $showDeleteConfirm) {
                Alert(
                    title: Text("Delete this trip?"),
                    message: Text("\(trip.name) will be removed permanently."),
                    primaryButton: .destructive(Text("Delete")) {
                        tripVM.deleteTrip(trip)
                        appState.notify(.warning)
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private var header: some View {
        OGCard {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(OGTheme.oceanGradient)
                        .frame(width: 80, height: 80)
                    Image(systemName: "ferry.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text(trip.name)
                    .font(.ogTitle(20))
                    .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                    .multilineTextAlignment(.center)
                if !trip.routeName.isEmpty {
                    Text(trip.routeName)
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

    private var statsGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            statTile(title: "Distance", value: String(format: "%.2f", trip.distanceNM), unit: "NM", icon: "map", color: OGTheme.ocean)
            statTile(title: "Duration", value: trip.durationFormatted, unit: "", icon: "clock", color: OGTheme.depth)
            statTile(title: "Avg Speed", value: String(format: "%.1f", trip.avgSpeedKnots), unit: "kn", icon: "speedometer", color: OGTheme.success)
            statTile(title: "Max Speed", value: String(format: "%.1f", trip.maxSpeedKnots), unit: "kn", icon: "bolt.fill", color: OGTheme.warning)
            statTile(title: "Fuel Used", value: String(format: "%.1f", trip.fuelUsedLiters), unit: "L", icon: "fuelpump", color: OGTheme.coral)
            statTile(title: "L per NM", value: trip.distanceNM > 0 ? String(format: "%.2f", trip.fuelUsedLiters / trip.distanceNM) : "—", unit: "L/NM", icon: "drop.fill", color: OGTheme.danger)
        }
    }

    private func statTile(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        OGCard(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(color)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(color.opacity(0.15)))
                    Spacer()
                }
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(value)
                        .font(.ogTitle(22))
                        .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.ogCaption(11))
                            .foregroundColor(.secondary)
                    }
                }
                Text(title)
                    .font(.ogCaption(11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var timingCard: some View {
        OGCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(OGTheme.success)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Started")
                            .font(.ogCaption(11))
                            .foregroundColor(.secondary)
                        Text(DateFormatter.short.string(from: trip.startDate))
                            .font(.ogHeadline(14))
                            .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                    }
                    Spacer()
                }
                Divider().background(Color.gray.opacity(0.15))
                HStack(spacing: 10) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(OGTheme.coral)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ended")
                            .font(.ogCaption(11))
                            .foregroundColor(.secondary)
                        Text(DateFormatter.short.string(from: trip.endDate))
                            .font(.ogHeadline(14))
                            .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                    }
                    Spacer()
                }
            }
        }
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            OGSectionHeader(title: "Notes")
            OGCard {
                Text(trip.notes)
                    .font(.ogBody(14))
                    .foregroundColor(scheme == .dark ? .white.opacity(0.9) : OGTheme.nightBlue.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Statistics View

struct StatisticsView: View {
    @EnvironmentObject var tripVM: TripViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme

    enum Range: String, CaseIterable, Identifiable {
        case week = "7D"
        case month = "30D"
        case year = "1Y"
        case all = "All"
        var id: String { rawValue }
    }

    @State private var range: Range = .month

    var body: some View {
        OGBackground {
            ScrollView {
                VStack(spacing: 18) {
                    rangePicker
                    headlineStats
                    distanceChart
                    fuelEfficiency
                    breakdownCards
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var filtered: [Trip] {
        let now = Date()
        let cutoff: Date?
        switch range {
        case .week: cutoff = Calendar.current.date(byAdding: .day, value: -7, to: now)
        case .month: cutoff = Calendar.current.date(byAdding: .day, value: -30, to: now)
        case .year: cutoff = Calendar.current.date(byAdding: .year, value: -1, to: now)
        case .all: cutoff = nil
        }
        let trips = tripVM.trips.sorted { $0.startDate < $1.startDate }
        guard let cutoff = cutoff else { return trips }
        return trips.filter { $0.startDate >= cutoff }
    }

    private var rangePicker: some View {
        HStack(spacing: 8) {
            ForEach(Range.allCases) { r in
                Button {
                    appState.haptic(.light)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        range = r
                    }
                } label: {
                    Text(r.rawValue)
                        .font(.ogHeadline(13))
                        .foregroundColor(range == r ? .white : (scheme == .dark ? .white : OGTheme.nightBlue))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(range == r ? OGTheme.ocean : Color.gray.opacity(0.12))
                        )
                }
            }
        }
    }

    private var headlineStats: some View {
        let trips = filtered
        let totalNM = trips.reduce(0) { $0 + $1.distanceNM }
        let totalFuel = trips.reduce(0) { $0 + $1.fuelUsedLiters }
        let totalHours = trips.reduce(0.0) { $0 + $1.duration / 3600 }
        let count = trips.count
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            statTile(title: "Trips", value: "\(count)", unit: "", icon: "ferry", color: OGTheme.ocean)
            statTile(title: "Distance", value: String(format: "%.1f", totalNM), unit: "NM", icon: "map", color: OGTheme.depth)
            statTile(title: "Time at Sea", value: String(format: "%.1f", totalHours), unit: "h", icon: "clock", color: OGTheme.success)
            statTile(title: "Fuel Used", value: String(format: "%.0f", totalFuel), unit: "L", icon: "fuelpump", color: OGTheme.coral)
        }
    }

    private func statTile(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        OGCard(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(color)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(color.opacity(0.15)))
                    Spacer()
                }
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(value)
                        .font(.ogTitle(22))
                        .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.ogCaption(11))
                            .foregroundColor(.secondary)
                    }
                }
                Text(title)
                    .font(.ogCaption(11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var distanceChart: some View {
        let data = filtered.suffix(12).map { $0.distanceNM }
        let maxV = max(1, data.max() ?? 1)
        return VStack(alignment: .leading, spacing: 10) {
            OGSectionHeader(title: "Distance per Trip", subtitle: "Last \(data.count) trips")
            OGCard {
                if data.isEmpty {
                    Text("No data for this range")
                        .font(.ogBody(14))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    GeometryReader { geo in
                        let barW = (geo.size.width - CGFloat(data.count - 1) * 6) / CGFloat(max(1, data.count))
                        HStack(alignment: .bottom, spacing: 6) {
                            ForEach(Array(data.enumerated()), id: \.offset) { _, v in
                                let h = max(4, geo.size.height * CGFloat(v / maxV))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(LinearGradient(
                                        colors: [OGTheme.ocean, OGTheme.depth],
                                        startPoint: .top, endPoint: .bottom
                                    ))
                                    .frame(width: barW, height: h)
                            }
                        }
                    }
                    .frame(height: 140)
                }
            }
        }
    }

    private var fuelEfficiency: some View {
        let trips = filtered
        let totalNM = trips.reduce(0) { $0 + $1.distanceNM }
        let totalFuel = trips.reduce(0) { $0 + $1.fuelUsedLiters }
        let avgLNM = totalNM > 0 ? totalFuel / totalNM : 0
        let avgSpeed = trips.isEmpty ? 0 : trips.reduce(0) { $0 + $1.avgSpeedKnots } / Double(trips.count)
        return VStack(alignment: .leading, spacing: 10) {
            OGSectionHeader(title: "Efficiency")
            OGCard {
                VStack(spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Avg fuel rate")
                                .font(.ogCaption(12))
                                .foregroundColor(.secondary)
                            HStack(alignment: .firstTextBaseline, spacing: 3) {
                                Text(String(format: "%.2f", avgLNM))
                                    .font(.ogTitle(24))
                                    .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                                Text("L/NM")
                                    .font(.ogCaption(11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 32))
                            .foregroundColor(OGTheme.success.opacity(0.8))
                    }
                    Divider().background(Color.gray.opacity(0.15))
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Avg speed")
                                .font(.ogCaption(12))
                                .foregroundColor(.secondary)
                            HStack(alignment: .firstTextBaseline, spacing: 3) {
                                Text(String(format: "%.1f", avgSpeed))
                                    .font(.ogTitle(24))
                                    .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                                Text("kn")
                                    .font(.ogCaption(11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "speedometer")
                            .font(.system(size: 32))
                            .foregroundColor(OGTheme.ocean.opacity(0.8))
                    }
                }
            }
        }
    }

    private var breakdownCards: some View {
        let trips = filtered
        let longest = trips.max { $0.distanceNM < $1.distanceNM }
        let fastest = trips.max { $0.maxSpeedKnots < $1.maxSpeedKnots }
        return VStack(alignment: .leading, spacing: 10) {
            OGSectionHeader(title: "Records")
            VStack(spacing: 10) {
                recordRow(title: "Longest trip", value: longest.map { String(format: "%.1f NM", $0.distanceNM) } ?? "—", subtitle: longest?.name ?? "—", icon: "ruler", color: OGTheme.ocean)
                recordRow(title: "Top speed", value: fastest.map { String(format: "%.1f kn", $0.maxSpeedKnots) } ?? "—", subtitle: fastest?.name ?? "—", icon: "bolt.fill", color: OGTheme.warning)
            }
        }
    }

    private func recordRow(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        OGCard(padding: 14) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(color.opacity(0.15)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.ogCaption(11))
                        .foregroundColor(.secondary)
                    Text(subtitle)
                        .font(.ogHeadline(14))
                        .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                        .lineLimit(1)
                }
                Spacer()
                Text(value)
                    .font(.ogHeadline(15))
                    .foregroundColor(color)
            }
        }
    }
}

// MARK: - History View (chronological grouped by month)

struct HistoryView: View {
    @EnvironmentObject var tripVM: TripViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme

    @State private var selectedTrip: Trip? = nil

    var body: some View {
        OGBackground {
            ScrollView {
                VStack(spacing: 16) {
                    if tripVM.trips.isEmpty {
                        emptyState
                    } else {
                        ForEach(groupedKeys, id: \.self) { key in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(key)
                                        .font(.ogHeadline(15))
                                        .foregroundColor(OGTheme.ocean)
                                    Spacer()
                                    Text("\(grouped[key]?.count ?? 0)")
                                        .font(.ogCaption(11))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(Color.gray.opacity(0.15)))
                                }
                                .padding(.horizontal, 4)
                                VStack(spacing: 8) {
                                    ForEach(grouped[key] ?? []) { trip in
                                        Button {
                                            appState.haptic(.light)
                                            selectedTrip = trip
                                        } label: {
                                            historyRow(trip)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedTrip) { trip in
            TripDetailView(trip: trip)
                .environmentObject(tripVM)
                .environmentObject(appState)
        }
    }

    private var grouped: [String: [Trip]] {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        let sorted = tripVM.trips.sorted { $0.startDate > $1.startDate }
        return Dictionary(grouping: sorted) { f.string(from: $0.startDate) }
    }

    private var groupedKeys: [String] {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        let keys = grouped.keys
        return keys.sorted { a, b in
            let da = f.date(from: a) ?? Date.distantPast
            let db = f.date(from: b) ?? Date.distantPast
            return da > db
        }
    }

    private func historyRow(_ trip: Trip) -> some View {
        OGCard(padding: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(OGTheme.ocean.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "ferry.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(OGTheme.ocean)
                    )
                VStack(alignment: .leading, spacing: 3) {
                    Text(trip.name)
                        .font(.ogHeadline(14))
                        .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Text(DateFormatter.dayShort.string(from: trip.startDate))
                            .font(.ogCaption(11))
                            .foregroundColor(.secondary)
                        Text("·")
                            .font(.ogCaption(11))
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f NM", trip.distanceNM))
                            .font(.ogCaption(11))
                            .foregroundColor(.secondary)
                        Text("·")
                            .font(.ogCaption(11))
                            .foregroundColor(.secondary)
                        Text(trip.durationFormatted)
                            .font(.ogCaption(11))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundColor(OGTheme.ocean)
            Text("No history yet")
                .font(.ogHeadline(17))
                .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
            Text("Your trip history will appear here.")
                .font(.ogCaption(13))
                .foregroundColor(.secondary)
        }
        .padding(.top, 60)
    }
}
