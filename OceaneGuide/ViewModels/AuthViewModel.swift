import Foundation
import SwiftUI

final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var errorMessage: String?

    private let usersKey = "og.users"
    private let currentUserKey = "og.currentUser"

    init() {
        if let user: User = Persistence.load(User.self, key: currentUserKey) {
            currentUser = user
            isAuthenticated = true
        }
    }

    private var allUsers: [User] {
        get { Persistence.load([User].self, key: usersKey) ?? [] }
        set { Persistence.save(newValue, key: usersKey) }
    }

    @discardableResult
    func register(name: String, email: String, password: String) -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your name"
            return false
        }
        guard isValidEmail(trimmedEmail) else {
            errorMessage = "Please enter a valid email"
            return false
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return false
        }
        var users = allUsers
        if users.contains(where: { $0.email.lowercased() == trimmedEmail }) {
            errorMessage = "This email is already registered"
            return false
        }
        let user = User(name: name, email: trimmedEmail, passwordHash: hash(password))
        users.append(user)
        allUsers = users
        currentUser = user
        Persistence.save(user, key: currentUserKey)
        isAuthenticated = true
        errorMessage = nil
        return true
    }

    @discardableResult
    func login(email: String, password: String) -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard let user = allUsers.first(where: { $0.email.lowercased() == trimmedEmail }) else {
            errorMessage = "No account found for this email"
            return false
        }
        guard user.passwordHash == hash(password) else {
            errorMessage = "Incorrect password"
            return false
        }
        currentUser = user
        Persistence.save(user, key: currentUserKey)
        isAuthenticated = true
        errorMessage = nil
        return true
    }

    func loginAsGuest() {
        let demo = User(name: "Demo Captain",
                        email: "demo@oceanguide.app",
                        passwordHash: "",
                        avatarSymbol: "sailboat.fill",
                        isDemo: true)
        currentUser = demo
        Persistence.save(demo, key: currentUserKey)
        isAuthenticated = true
        errorMessage = nil
    }

    func logout() {
        Persistence.remove(key: currentUserKey)
        currentUser = nil
        isAuthenticated = false
    }

    func deleteAccount() {
        guard let user = currentUser else { return }
        if !user.isDemo {
            var users = allUsers
            users.removeAll { $0.id == user.id }
            allUsers = users
        }
        // Wipe linked data
        Persistence.remove(key: "og.vessel")
        Persistence.remove(key: "og.routes")
        Persistence.remove(key: "og.trips")
        Persistence.remove(key: "og.alerts")
        Persistence.remove(key: "og.checklist")
        Persistence.remove(key: "og.notifications")
        Persistence.remove(key: currentUserKey)
        currentUser = nil
        isAuthenticated = false
    }

    func updateProfile(name: String, avatarSymbol: String) {
        guard var user = currentUser else { return }
        user.name = name
        user.avatarSymbol = avatarSymbol
        currentUser = user
        Persistence.save(user, key: currentUserKey)
        if !user.isDemo {
            var users = allUsers
            if let idx = users.firstIndex(where: { $0.id == user.id }) {
                users[idx] = user
                allUsers = users
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^\S+@\S+\.\S+$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    private func hash(_ str: String) -> String {
        // Lightweight hash — sufficient for a local-only demo app
        var h: UInt64 = 5381
        for ch in str.unicodeScalars {
            h = ((h << 5) &+ h) &+ UInt64(ch.value)
        }
        return String(h)
    }
}
