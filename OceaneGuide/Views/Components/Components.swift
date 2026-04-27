import SwiftUI

// MARK: - Primary Button

struct OGPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView().progressViewStyle(.circular).tint(.white)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.ogHeadline(17))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(OGTheme.oceanGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: OGTheme.ocean.opacity(0.35), radius: 12, x: 0, y: 6)
            .scaleEffect(pressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
        .pressEvents(onPress: { pressed = true }, onRelease: { pressed = false })
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pressed)
    }
}

// MARK: - Secondary Button

struct OGSecondaryButton: View {
    let title: String
    var icon: String? = nil
    var action: () -> Void

    @State private var pressed = false
    @Environment(\.colorScheme) var scheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                }
                Text(title).font(.ogHeadline(16))
            }
            .foregroundColor(scheme == .dark ? .white : OGTheme.depth)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(scheme == .dark ? Color.white.opacity(0.08) : OGTheme.light.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(OGTheme.ocean.opacity(0.5), lineWidth: 1.2)
            )
            .scaleEffect(pressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
        .pressEvents(onPress: { pressed = true }, onRelease: { pressed = false })
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pressed)
    }
}

// MARK: - Ghost button

struct OGGhostButton: View {
    let title: String
    var icon: String? = nil
    var action: () -> Void
    @Environment(\.colorScheme) var scheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title).font(.ogHeadline(15))
            }
            .foregroundColor(OGTheme.ocean)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Card

struct OGCard<Content: View>: View {
    @Environment(\.colorScheme) var scheme
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(scheme == .dark
                          ? Color.white.opacity(0.06)
                          : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(scheme == .dark
                            ? Color.white.opacity(0.08)
                            : OGTheme.light, lineWidth: 1)
            )
            .shadow(color: scheme == .dark
                    ? .clear
                    : OGTheme.depth.opacity(0.08),
                    radius: 14, x: 0, y: 6)
    }
}

// MARK: - Text field

struct OGTextField: View {
    let title: String
    let icon: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default
    var capitalize: Bool = false

    @FocusState private var focused: Bool
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(focused ? OGTheme.ocean : .secondary)
                .frame(width: 22)

            Group {
                if isSecure {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                        .keyboardType(keyboard)
                        .autocapitalization(capitalize ? .words : .none)
                        .disableAutocorrection(true)
                }
            }
            .font(.ogBody())
            .focused($focused)

            if !text.isEmpty && !isSecure {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(scheme == .dark
                      ? Color.white.opacity(0.06)
                      : OGTheme.light.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(focused ? OGTheme.ocean : Color.clear, lineWidth: 1.5)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: focused)
    }
}

// MARK: - Section header

struct OGSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var trailing: AnyView? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.ogHeadline(20))
                if let subtitle {
                    Text(subtitle)
                        .font(.ogCaption(13))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if let trailing { trailing }
        }
    }
}

// MARK: - Stat tile

struct OGStatTile: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    var color: Color = OGTheme.ocean

    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(color.opacity(0.15)))
                Text(title)
                    .font(.ogCaption(12))
                    .foregroundColor(.secondary)
                Spacer()
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.ogTitle(24))
                    .foregroundColor(scheme == .dark ? .white : OGTheme.nightBlue)
                Text(unit)
                    .font(.ogCaption(12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(scheme == .dark ? Color.white.opacity(0.06) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(scheme == .dark ? Color.white.opacity(0.08) : OGTheme.light, lineWidth: 1)
        )
    }
}

// MARK: - Press events

struct PressActions: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressActions(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Background wrapper

struct OGBackground<Content: View>: View {
    @Environment(\.colorScheme) var scheme
    @ViewBuilder var content: Content
    var body: some View {
        ZStack {
            OGTheme.adaptiveBackground(scheme).ignoresSafeArea()
            // Decorative blobs
            Circle()
                .fill(OGTheme.ocean.opacity(scheme == .dark ? 0.18 : 0.15))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: -140, y: -260)
            Circle()
                .fill(OGTheme.depth.opacity(scheme == .dark ? 0.20 : 0.10))
                .frame(width: 360, height: 360)
                .blur(radius: 90)
                .offset(x: 160, y: 320)
            content
        }
    }
}

// MARK: - Toggle row

struct OGToggleRow: View {
    let title: String
    let icon: String
    var subtitle: String? = nil
    @Binding var isOn: Bool
    var tint: Color = OGTheme.ocean

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 32, height: 32)
                .background(LinearGradient(colors: [tint, tint.opacity(0.7)],
                                           startPoint: .top, endPoint: .bottom))
                .cornerRadius(10)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.ogBody(15))
                if let subtitle { Text(subtitle).font(.ogCaption(12)).foregroundColor(.secondary) }
            }
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden().tint(OGTheme.ocean)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Picker row

struct OGPickerRow<T: Hashable & Identifiable>: View {
    let title: String
    let icon: String
    @Binding var selection: T
    let options: [T]
    let label: (T) -> String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 32, height: 32)
                .background(LinearGradient(colors: [OGTheme.depth, OGTheme.ocean],
                                           startPoint: .top, endPoint: .bottom))
                .cornerRadius(10)
            Text(title).font(.ogBody(15))
            Spacer()
            Menu {
                ForEach(options) { opt in
                    Button(label(opt)) { selection = opt }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(label(selection))
                        .font(.ogCaption(13))
                        .foregroundColor(OGTheme.ocean)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(OGTheme.ocean)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(OGTheme.ocean.opacity(0.12))
                .cornerRadius(10)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Settings group

struct OGSettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.ogCaption(11))
                .foregroundColor(.secondary)
                .padding(.leading, 6)
            VStack(spacing: 2) {
                content
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(scheme == .dark ? Color.white.opacity(0.06) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(scheme == .dark ? Color.white.opacity(0.08) : OGTheme.light, lineWidth: 1)
            )
        }
    }
}
