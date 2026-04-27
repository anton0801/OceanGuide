import Foundation
import Combine

final class RouteViewModel: ObservableObject {
    @Published var routes: [Route] = []
    @Published var activeRoute: Route?

    private let routesKey = "og.routes"

    init() {
        if let saved: [Route] = Persistence.load([Route].self, key: routesKey) {
            self.routes = saved
            self.activeRoute = saved.first(where: { $0.isActive })
        } else {
            seed()
        }
    }

    private func seed() {
        let r1 = Route(
            name: "Coastal Cruise",
            waypoints: [
                Waypoint(name: "Marina Salinas", latitude: 37.9760, longitude: -0.6803),
                Waypoint(name: "La Manga", latitude: 37.7800, longitude: -0.7400),
                Waypoint(name: "Cabo de Palos", latitude: 37.6300, longitude: -0.6900)
            ]
        )
        let r2 = Route(
            name: "Open Sea Run",
            waypoints: [
                Waypoint(name: "Departure", latitude: 38.0000, longitude: -0.5000),
                Waypoint(name: "Mid Sea", latitude: 38.4000, longitude: -0.2000),
                Waypoint(name: "Ibiza Approach", latitude: 38.9100, longitude: 1.4300)
            ]
        )
        routes = [r1, r2]
        persist()
    }

    func addRoute(_ route: Route) {
        routes.append(route)
        persist()
    }

    func updateRoute(_ route: Route) {
        if let i = routes.firstIndex(where: { $0.id == route.id }) {
            routes[i] = route
            if route.isActive { activeRoute = route }
            persist()
        }
    }

    func deleteRoute(_ route: Route) {
        routes.removeAll { $0.id == route.id }
        if activeRoute?.id == route.id { activeRoute = nil }
        persist()
    }

    func setActive(_ route: Route) {
        for i in routes.indices { routes[i].isActive = false }
        if let i = routes.firstIndex(where: { $0.id == route.id }) {
            routes[i].isActive = true
            activeRoute = routes[i]
        }
        persist()
    }

    func clearActive() {
        for i in routes.indices { routes[i].isActive = false }
        activeRoute = nil
        persist()
    }

    func addWaypoint(_ wp: Waypoint, to routeID: UUID) {
        if let i = routes.firstIndex(where: { $0.id == routeID }) {
            routes[i].waypoints.append(wp)
            if routes[i].isActive { activeRoute = routes[i] }
            persist()
        }
    }

    func removeWaypoint(_ wp: Waypoint, from routeID: UUID) {
        if let i = routes.firstIndex(where: { $0.id == routeID }) {
            routes[i].waypoints.removeAll { $0.id == wp.id }
            if routes[i].isActive { activeRoute = routes[i] }
            persist()
        }
    }

    private func persist() {
        Persistence.save(routes, key: routesKey)
    }
}
