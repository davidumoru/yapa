import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

@Observable
final class AppSettings {
    static let shared = AppSettings()

    var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "appTheme") }
    }

    var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: "hapticsEnabled") }
    }

    var defaultReminderHour: Int {
        didSet { UserDefaults.standard.set(defaultReminderHour, forKey: "defaultReminderHour") }
    }

    var defaultReminderMinute: Int {
        didSet { UserDefaults.standard.set(defaultReminderMinute, forKey: "defaultReminderMinute") }
    }

    private init() {
        let savedTheme = UserDefaults.standard.string(forKey: "appTheme") ?? "system"
        self.theme = AppTheme(rawValue: savedTheme) ?? .system
        self.hapticsEnabled = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
        self.defaultReminderHour = UserDefaults.standard.object(forKey: "defaultReminderHour") as? Int ?? 9
        self.defaultReminderMinute = UserDefaults.standard.object(forKey: "defaultReminderMinute") as? Int ?? 0
    }

    func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func notificationHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
