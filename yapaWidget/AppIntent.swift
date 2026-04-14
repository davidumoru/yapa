import AppIntents
import SwiftData

struct HabitEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Habit")
    static var defaultQuery = HabitEntityQuery()

    var id: String
    var name: String
    var emoji: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(emoji) \(name)")
    }
}

struct HabitEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [HabitEntity] {
        let all = try await suggestedEntities()
        return all.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [HabitEntity] {
        await fetchAll()
    }

    func defaultResult() async -> HabitEntity? {
        try? await suggestedEntities().first
    }

    @MainActor
    private func fetchAll() -> [HabitEntity] {
        let ctx = WidgetData.container.mainContext
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\Habit.sortOrder)]
        )
        guard let habits = try? ctx.fetch(descriptor) else { return [] }
        return habits.map { HabitEntity(id: $0.id.uuidString, name: $0.name, emoji: $0.emoji) }
    }
}

struct SelectHabitIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Habit"
    static var description = IntentDescription("Choose a habit to display on your home screen.")

    @Parameter(title: "Habit")
    var habit: HabitEntity?
}
