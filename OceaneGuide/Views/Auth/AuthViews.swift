import SwiftUI

// MARK: - Welcome (4)

struct WelcomeView: View {
    @State private var showLogin = false
    @State private var showRegister = false
    @State private var animateLogo = false
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationView {
            OGBackground {
                VStack {
                    Spacer()

                    // Brand
                    VStack(spacing: 18) {
                        ZStack {
                            Circle()
                                .fill(OGTheme.oceanGradient)
                                .frame(width: 130, height: 130)
                                .shadow(color: OGTheme.ocean.opacity(0.4), radius: 20, x: 0, y: 8)
                            Image(systemName: "sailboat.fill")
                                .font(.system(size: 56, weight: .black))
                                .foregroundColor(.white)
                                .scaleEffect(animateLogo ? 1.0 : 0.85)
                        }
                        Text("Ocean Guide")
                            .font(.ogTitle(34))
                        Text("Your sea command center")
                            .font(.ogBody(15))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(spacing: 14) {
                        OGPrimaryButton(title: "Log In", icon: "arrow.right.circle.fill") {
                            appState.haptic(.light)
                            showLogin = true
                        }
                        OGSecondaryButton(title: "Create Account", icon: "person.crop.circle.badge.plus") {
                            appState.haptic(.light)
                            showRegister = true
                        }

                        Button {
                            appState.haptic(.medium)
                            authVM.loginAsGuest()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "person.crop.circle.dashed")
                                Text("Continue as Guest (Demo)")
                            }
                            .font(.ogHeadline(15))
                            .foregroundColor(OGTheme.ocean)
                            .padding(.vertical, 12)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 28)
                }

                NavigationLink(isActive: $showLogin) {
                    LoginView()
                } label: { EmptyView() }

                NavigationLink(isActive: $showRegister) {
                    RegisterView()
                } label: { EmptyView() }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.55).repeatForever(autoreverses: true)) {
                    animateLogo.toggle()
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Login (6)

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var localError: String?

    var body: some View {
        OGBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Welcome back")
                            .font(.ogTitle(30))
                        Text("Log in to chart your next voyage")
                            .font(.ogBody(15))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 12)

                    VStack(spacing: 14) {
                        OGTextField(title: "Email", icon: "envelope.fill", text: $email,
                                    keyboard: .emailAddress)
                        OGTextField(title: "Password", icon: "lock.fill", text: $password, isSecure: true)
                    }

                    if let err = localError ?? authVM.errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill").foregroundColor(OGTheme.danger)
                            Text(err).font(.ogCaption(13)).foregroundColor(OGTheme.danger)
                        }
                    }

                    OGPrimaryButton(title: "Log In", icon: "arrow.right") {
                        attemptLogin()
                    }

                    HStack {
                        Rectangle().fill(Color.secondary.opacity(0.25)).frame(height: 1)
                        Text("OR").font(.ogCaption(11)).foregroundColor(.secondary)
                        Rectangle().fill(Color.secondary.opacity(0.25)).frame(height: 1)
                    }
                    .padding(.vertical, 4)

                    // Demo account button — always visible
                    Button {
                        appState.haptic(.medium)
                        authVM.loginAsGuest()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles")
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Try Demo Account").font(.ogHeadline(15))
                                Text("Explore the app instantly — no sign up needed")
                                    .font(.ogCaption(12)).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(OGTheme.ocean)
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(OGTheme.ocean.opacity(0.10))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(OGTheme.ocean.opacity(0.4), style: StrokeStyle(lineWidth: 1.2, dash: [5,4]))
                        )
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 22)
            }
        }
        .navigationTitle("Log In")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func attemptLogin() {
        localError = nil
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.isEmpty else {
            localError = "Please fill in both fields"
            appState.notify(.error)
            return
        }
        if authVM.login(email: email, password: password) {
            appState.notify(.success)
        } else {
            appState.notify(.error)
        }
    }
}

// MARK: - Register (5)

struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var appState: AppState

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirm = ""
    @State private var agree = false
    @State private var localError: String?

    var body: some View {
        OGBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Set sail")
                            .font(.ogTitle(30))
                        Text("Create your captain's account")
                            .font(.ogBody(15))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 12)

                    VStack(spacing: 14) {
                        OGTextField(title: "Full name", icon: "person.fill", text: $name, capitalize: true)
                        OGTextField(title: "Email", icon: "envelope.fill", text: $email, keyboard: .emailAddress)
                        OGTextField(title: "Password (min 6 chars)", icon: "lock.fill", text: $password, isSecure: true)
                        OGTextField(title: "Confirm password", icon: "lock.shield.fill", text: $confirm, isSecure: true)
                    }

                    Toggle(isOn: $agree) {
                        Text("I agree to the Terms of Service and Privacy Policy")
                            .font(.ogCaption(13))
                    }
                    .toggleStyle(SwitchToggleStyle(tint: OGTheme.ocean))

                    if let err = localError ?? authVM.errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill").foregroundColor(OGTheme.danger)
                            Text(err).font(.ogCaption(13)).foregroundColor(OGTheme.danger)
                        }
                    }

                    OGPrimaryButton(title: "Create Account", icon: "checkmark") {
                        attemptRegister()
                    }

                    Button {
                        appState.haptic(.medium)
                        authVM.loginAsGuest()
                    } label: {
                        Text("Or continue as Demo Captain")
                            .font(.ogHeadline(14))
                            .foregroundColor(OGTheme.ocean)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 22)
            }
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func attemptRegister() {
        localError = nil
        guard agree else {
            localError = "Please accept Terms to continue"
            appState.notify(.warning)
            return
        }
        guard password == confirm else {
            localError = "Passwords don't match"
            appState.notify(.error)
            return
        }
        if authVM.register(name: name, email: email, password: password) {
            appState.notify(.success)
        } else {
            appState.notify(.error)
        }
    }
}
