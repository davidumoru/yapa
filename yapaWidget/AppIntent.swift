import WidgetKit
import AppIntents

// Placeholder — not used by the habit widget (uses StaticConfiguration)
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "Yapa widget configuration." }
}
