import SwiftUI
import SwiftData

struct CreateHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let habitToEdit: Habit?

    @State private var name: String
    @State private var emoji: String
    @State private var selectedColor: String
    @State private var isDaily: Bool
    @State private var selectedWeekdays: Set<Int>
    @State private var targetDays: Int
    @State private var graceDays: Int
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var showEmojiPicker = false

    private var isEditing: Bool { habitToEdit != nil }

    init(habitToEdit: Habit? = nil) {
        self.habitToEdit = habitToEdit
        if let h = habitToEdit {
            _name = State(initialValue: h.name)
            _emoji = State(initialValue: h.emoji)
            _selectedColor = State(initialValue: h.colorHex)
            _isDaily = State(initialValue: h.scheduledWeekdays.isEmpty)
            _selectedWeekdays = State(initialValue: Set(h.scheduledWeekdays))
            _targetDays = State(initialValue: h.targetDays)
            _graceDays = State(initialValue: h.graceDays)
            _reminderEnabled = State(initialValue: !h.reminderMinutes.isEmpty)
            if let first = h.reminderMinutes.first {
                _reminderTime = State(initialValue: Calendar.current.date(
                    from: DateComponents(hour: first / 60, minute: first % 60)
                ) ?? Date())
            } else {
                _reminderTime = State(initialValue: Calendar.current.date(
                    from: DateComponents(hour: 9, minute: 0)
                ) ?? Date())
            }
        } else {
            _name = State(initialValue: "")
            _emoji = State(initialValue: "🎯")
            _selectedColor = State(initialValue: "34C759")
            _isDaily = State(initialValue: true)
            _selectedWeekdays = State(initialValue: [])
            _targetDays = State(initialValue: 0)
            _graceDays = State(initialValue: 0)
            _reminderEnabled = State(initialValue: false)
            _reminderTime = State(initialValue: Calendar.current.date(
                from: DateComponents(hour: 9, minute: 0)
            ) ?? Date())
        }
    }

    private let colorOptions = [
        "34C759", "30D158", "007AFF", "5856D6",
        "AF52DE", "FF2D55", "FF9500", "FF3B30",
        "5AC8FA", "FFD60A", "BF5AF2", "64D2FF"
    ]

    private let emojiOptions = [
        "🎯", "💪", "📚", "🧘", "🏃", "💧", "🥗", "😴",
        "✍️", "🎨", "🎵", "💊", "🧹", "📱", "🌅", "🧠",
        "💰", "🌿", "❤️", "⏰", "🚶", "🍎", "📝", "🔥"
    ]

    private let durationOptions = [
        (0, "Forever"),
        (21, "21 days"),
        (30, "30 days"),
        (60, "60 days"),
        (90, "90 days"),
        (365, "1 year")
    ]

    private let weekdayNames = [
        (1, "Sun"), (2, "Mon"), (3, "Tue"), (4, "Wed"),
        (5, "Thu"), (6, "Fri"), (7, "Sat")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    emojiSection
                    nameSection
                    colorSection
                    frequencySection
                    durationSection
                    graceDaysSection
                    reminderSection
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(isEditing ? "Edit Habit" : "New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Update" : "Save") { save() }
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // MARK: - Sections

    private var emojiSection: some View {
        VStack(spacing: 12) {
            Button { showEmojiPicker.toggle() } label: {
                Text(emoji)
                    .font(.system(size: 56))
                    .frame(width: 88, height: 88)
                    .background(Color(hex: selectedColor).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }

            if showEmojiPicker {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 8) {
                    ForEach(emojiOptions, id: \.self) { e in
                        Button {
                            emoji = e
                            showEmojiPicker = false
                        } label: {
                            Text(e)
                                .font(.system(size: 28))
                                .frame(width: 44, height: 44)
                                .background(
                                    emoji == e
                                        ? Color(hex: selectedColor).opacity(0.2)
                                        : Color(.systemGray6)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.3), value: showEmojiPicker)
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("NAME")

            TextField("e.g. Morning meditation", text: $name)
                .font(.system(.body, design: .rounded))
                .padding(14)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("COLOR")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                ForEach(colorOptions, id: \.self) { hex in
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .strokeBorder(.white, lineWidth: 3)
                                .opacity(selectedColor == hex ? 1 : 0)
                        )
                        .shadow(color: Color(hex: hex).opacity(selectedColor == hex ? 0.4 : 0), radius: 4, y: 2)
                        .onTapGesture { selectedColor = hex }
                }
            }
            .padding(14)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("FREQUENCY")

            VStack(spacing: 12) {
                Picker("Frequency", selection: $isDaily) {
                    Text("Every day").tag(true)
                    Text("Specific days").tag(false)
                }
                .pickerStyle(.segmented)

                if !isDaily {
                    HStack(spacing: 8) {
                        ForEach(weekdayNames, id: \.0) { day in
                            Button {
                                if selectedWeekdays.contains(day.0) {
                                    selectedWeekdays.remove(day.0)
                                } else {
                                    selectedWeekdays.insert(day.0)
                                }
                            } label: {
                                Text(day.1)
                                    .font(.system(.caption, design: .rounded, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        selectedWeekdays.contains(day.0)
                                            ? Color(hex: selectedColor)
                                            : Color(.systemGray5)
                                    )
                                    .foregroundStyle(selectedWeekdays.contains(day.0) ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(14)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .animation(.spring(response: 0.3), value: isDaily)
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("DURATION")

            FlowLayout(spacing: 8) {
                ForEach(durationOptions, id: \.0) { option in
                    Button {
                        targetDays = option.0
                    } label: {
                        Text(option.1)
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                targetDays == option.0
                                    ? Color(hex: selectedColor)
                                    : Color(.systemGray5)
                            )
                            .foregroundStyle(targetDays == option.0 ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(14)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var graceDaysSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("STREAK PROTECTION")

            VStack(spacing: 8) {
                HStack {
                    Label("Grace days", systemImage: "shield.fill")
                        .font(.system(.body, design: .rounded))

                    Spacer()

                    Picker("Grace days", selection: $graceDays) {
                        Text("None").tag(0)
                        Text("1 day").tag(1)
                        Text("2 days").tag(2)
                    }
                    .pickerStyle(.menu)
                    .tint(Color(hex: selectedColor))
                }

                Text("Miss up to \(graceDays == 0 ? "0 days" : "\(graceDays) day\(graceDays > 1 ? "s" : "")") in a row without losing your streak.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("REMINDER")

            VStack(spacing: 12) {
                Toggle(isOn: $reminderEnabled) {
                    Label("Daily reminder", systemImage: "bell.fill")
                        .font(.system(.body, design: .rounded))
                }

                if reminderEnabled {
                    DatePicker(
                        "Time",
                        selection: $reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .font(.system(.body, design: .rounded))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(14)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .animation(.spring(response: 0.3), value: reminderEnabled)
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        var reminders: [Int] = []
        if reminderEnabled {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            reminders.append((comps.hour ?? 9) * 60 + (comps.minute ?? 0))
        }

        let weekdays = isDaily ? [Int]() : Array(selectedWeekdays).sorted()

        if let habit = habitToEdit {
            habit.name = trimmed
            habit.emoji = emoji
            habit.colorHex = selectedColor
            habit.scheduledWeekdays = weekdays
            habit.targetDays = targetDays
            habit.graceDays = graceDays
            habit.reminderMinutes = reminders
        } else {
            let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\Habit.sortOrder, order: .reverse)])
            let maxOrder = (try? modelContext.fetch(descriptor).first?.sortOrder) ?? -1

            let habit = Habit(
                name: trimmed,
                emoji: emoji,
                colorHex: selectedColor,
                scheduledWeekdays: weekdays,
                targetDays: targetDays,
                reminderMinutes: reminders,
                graceDays: graceDays
            )
            habit.sortOrder = maxOrder + 1
            modelContext.insert(habit)
        }

        try? modelContext.save()

        if let habit = habitToEdit ?? (try? modelContext.fetch(FetchDescriptor<Habit>(
            predicate: #Predicate { $0.name == trimmed },
            sortBy: [SortDescriptor(\Habit.createdAt, order: .reverse)]
        )).first) {
            if reminderEnabled {
                Task {
                    await NotificationManager.shared.requestAuthorization()
                    NotificationManager.shared.scheduleReminders(for: habit)
                }
            } else {
                NotificationManager.shared.removeReminders(for: habit)
            }
        }

        AppSettings.shared.haptic(.medium)
        dismiss()
    }
}

// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (positions, CGSize(width: maxWidth, height: y + rowHeight))
    }
}
