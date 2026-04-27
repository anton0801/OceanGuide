import SwiftUI

// MARK: - Route Planner (9)

struct RoutePlannerView: View {
    @EnvironmentObject var routeVM: RouteViewModel
    @EnvironmentObject var appState: AppState
    @State private var showAddRoute = false
    @State private var addingWaypointFor: Route?

    var body: some View {
        OGBackground {
            ScrollView {
                VStack(spacing: 14) {
                    OGSectionHeader(
                        title: "Your Routes",
                        subtitle: "Tap a route to make it active",
                        trailing: AnyView(
                            Button {
                                showAddRoute = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(OGTheme.ocean)
                            }
                        )
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    if routeVM.routes.isEmpty {
                        emptyState.padding(.top, 60)
                    }

                    ForEach(routeVM.routes) { route in
                        RouteRow(route: route,
                                 isActive: route.id == routeVM.activeRoute?.id,
                                 onActivate: {
                                    appState.haptic(.medium)
                                    routeVM.setActive(route)
                                 },
                                 onDelete: {
                                    appState.haptic(.heavy)
                                    routeVM.deleteRoute(route)
                                 },
                                 onAddWaypoint: { addingWaypointFor = route }
                        )
                        .padding(.horizontal, 16)
                    }
                    Color.clear.frame(height: 100)
                }
            }
        }
        .navigationTitle("Route Planner")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddRoute) {
            NewRouteSheet()
        }
        .sheet(item: $addingWaypointFor) { route in
            NavigationView {
                AddWaypointView(routeID: route.id)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "point.topleft.down.curvedto.point.bottomright.up.fill")
                .font(.system(size: 60))
                .foregroundColor(OGTheme.ocean.opacity(0.6))
            Text("No routes yet").font(.ogHeadline(18))
            Text("Create your first route to start planning")
                .font(.ogCaption(13))
                .foregroundColor(.secondary)
            OGPrimaryButton(title: "New Route", icon: "plus") {
                showAddRoute = true
            }
            .padding(.horizontal, 60)
        }
    }
}

struct RouteRow: View {
    let route: Route
    let isActive: Bool
    let onActivate: () -> Void
    let onDelete: () -> Void
    let onAddWaypoint: () -> Void

    @EnvironmentObject var appState: AppState
    @State private var expanded = false

    var body: some View {
        OGCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(route.name).font(.ogHeadline(17))
                            if isActive {
                                Text("ACTIVE")
                                    .font(.ogCaption(9).bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Capsule().fill(OGTheme.success))
                            }
                        }
                        Text(DateFormatter.short.string(from: route.createdAt))
                            .font(.ogCaption(11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        withAnimation { expanded.toggle() }
                    } label: {
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 14) {
                    Label(String(format: "%.1f %@",
                                 appState.distanceUnit.convert(fromNM: route.totalDistanceNM),
                                 appState.distanceUnit.short),
                          systemImage: "ruler")
                    Label(String(format: "%.1fh", route.estimatedHours), systemImage: "clock")
                    Label("\(route.waypoints.count) wp", systemImage: "flag")
                }
                .font(.ogCaption(12))
                .foregroundColor(.secondary)

                if expanded {
                    Divider()
                    ForEach(Array(zip(route.waypoints.indices, route.waypoints)), id: \.1.id) { i, wp in
                        HStack {
                            Text("\(i + 1)")
                                .font(.ogCaption(11).bold())
                                .foregroundColor(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(OGTheme.depth))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(wp.name).font(.ogBody(14))
                                Text(wp.coordinateString)
                                    .font(.ogMono(11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                }

                HStack(spacing: 8) {
                    Button {
                        onActivate()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isActive ? "checkmark.circle.fill" : "play.circle")
                            Text(isActive ? "Active" : "Set Active")
                        }
                        .font(.ogHeadline(13))
                        .foregroundColor(isActive ? OGTheme.success : OGTheme.ocean)
                        .padding(.vertical, 8).padding(.horizontal, 12)
                        .background(
                            Capsule().fill((isActive ? OGTheme.success : OGTheme.ocean).opacity(0.15))
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        onAddWaypoint()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("Waypoint")
                        }
                        .font(.ogHeadline(13))
                        .foregroundColor(OGTheme.depth)
                        .padding(.vertical, 8).padding(.horizontal, 12)
                        .background(Capsule().fill(OGTheme.depth.opacity(0.12)))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash.fill")
                            .foregroundColor(OGTheme.danger)
                            .padding(8)
                            .background(Circle().fill(OGTheme.danger.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct NewRouteSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var routeVM: RouteViewModel
    @EnvironmentObject var appState: AppState
    @State private var name: String = ""

    var body: some View {
        NavigationView {
            OGBackground {
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("New Route").font(.ogTitle(26))
                        Text("Give your route a name. You can add waypoints next.")
                            .font(.ogCaption(13))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    OGTextField(title: "Route name (e.g. Sunset Run)", icon: "tag.fill", text: $name)

                    OGPrimaryButton(title: "Create Route", icon: "checkmark") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else {
                            appState.notify(.error)
                            return
                        }
                        let r = Route(name: trimmed, waypoints: [])
                        routeVM.addRoute(r)
                        appState.notify(.success)
                        dismiss()
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("New Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Add Waypoint (10)

struct AddWaypointView: View {
    let routeID: UUID?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var routeVM: RouteViewModel
    @EnvironmentObject var appState: AppState

    @State private var name: String = ""
    @State private var latText: String = ""
    @State private var lonText: String = ""
    @State private var note: String = ""
    @State private var pickedRouteID: UUID? = nil
    @State private var localError: String?

    var body: some View {
        OGBackground {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Add Waypoint").font(.ogTitle(26))
                        Text("Enter coordinates and a label. They'll be added to your route.")
                            .font(.ogCaption(13)).foregroundColor(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)

                    OGCard {
                        VStack(spacing: 12) {
                            OGTextField(title: "Name (e.g. Marina Salinas)", icon: "tag.fill", text: $name, capitalize: true)
                            OGTextField(title: "Latitude (e.g. 37.9760)", icon: "globe", text: $latText, keyboard: .decimalPad)
                            OGTextField(title: "Longitude (e.g. -0.6803)", icon: "globe.americas", text: $lonText, keyboard: .decimalPad)
                            OGTextField(title: "Note (optional)", icon: "note.text", text: $note, capitalize: true)
                        }
                    }

                    if routeID == nil {
                        OGCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Add to route")
                                    .font(.ogCaption(12)).foregroundColor(.secondary)
                                Menu {
                                    ForEach(routeVM.routes) { r in
                                        Button(r.name) { pickedRouteID = r.id }
                                    }
                                } label: {
                                    HStack {
                                        Text(routeName)
                                            .font(.ogBody(15))
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                    }
                                    .foregroundColor(OGTheme.ocean)
                                }
                            }
                        }
                    }

                    if let err = localError {
                        Text(err).font(.ogCaption(12)).foregroundColor(OGTheme.danger)
                    }

                    OGPrimaryButton(title: "Save Waypoint", icon: "checkmark") {
                        save()
                    }

                    Spacer()
                }
                .padding(20)
            }
        }
        .navigationTitle("New Waypoint")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var routeName: String {
        let id = routeID ?? pickedRouteID
        if let id, let r = routeVM.routes.first(where: { $0.id == id }) { return r.name }
        return "Pick a route…"
    }

    private func save() {
        localError = nil
        let target = routeID ?? pickedRouteID
        guard let target else {
            localError = "Choose a route"
            appState.notify(.error)
            return
        }
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            localError = "Enter a name"
            appState.notify(.error)
            return
        }
        guard let lat = Double(latText), (-90...90).contains(lat) else {
            localError = "Latitude must be -90 to 90"
            appState.notify(.error)
            return
        }
        guard let lon = Double(lonText), (-180...180).contains(lon) else {
            localError = "Longitude must be -180 to 180"
            appState.notify(.error)
            return
        }
        let wp = Waypoint(name: name, latitude: lat, longitude: lon, note: note)
        routeVM.addWaypoint(wp, to: target)
        appState.notify(.success)
        dismiss()
    }
}
