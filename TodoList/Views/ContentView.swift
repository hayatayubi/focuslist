import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: TodoStore
    @State private var selectedCategory: TodoCategory?
    @State private var selectedFilter: TaskListFilter = .all
    @State private var searchText = ""
    @State private var editorRoute: TaskEditorRoute?

    private var visibleTasks: [TodoTask] {
        store.filteredTasks(
            in: selectedCategory,
            searchText: searchText,
            includeCompleted: selectedFilter == .completed
        )
        .filter { selectedFilter.contains($0) }
    }

    private var taskGroups: [TaskGroup] {
        switch selectedFilter {
        case .all:
            return [
                TaskGroup(title: "Overdue", tasks: visibleTasks.filter(\.isOverdue)),
                TaskGroup(title: "Today", tasks: visibleTasks.filter { $0.isDueToday && !$0.isOverdue }),
                TaskGroup(title: "Upcoming", tasks: visibleTasks.filter(\.isUpcoming)),
                TaskGroup(title: "No date", tasks: visibleTasks.filter(\.hasNoDueDate))
            ]
            .filter { !$0.tasks.isEmpty }
        case .today:
            return [TaskGroup(title: "Today", tasks: visibleTasks)].filter { !$0.tasks.isEmpty }
        case .upcoming:
            return [TaskGroup(title: "Upcoming", tasks: visibleTasks)].filter { !$0.tasks.isEmpty }
        case .completed:
            return [TaskGroup(title: "Completed", tasks: visibleTasks)].filter { !$0.tasks.isEmpty }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        HeaderView(filter: selectedFilter)

                        TaskFilterControl(selectedFilter: $selectedFilter)

                        SearchField(text: $searchText)

                        CategoryFilter(
                            selectedCategory: $selectedCategory,
                            categories: TodoCategory.allCases
                        )

                        TaskSection(
                            groups: taskGroups,
                            filter: selectedFilter,
                            searchText: searchText,
                            selectedCategory: selectedCategory,
                            onToggleTask: store.toggleCompletion,
                            onToggleSubtask: store.toggleSubtask,
                            onEdit: { editorRoute = TaskEditorRoute(task: $0) },
                            onDelete: store.delete
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 110)
                }

                AddTaskButton {
                    editorRoute = TaskEditorRoute(task: nil)
                }
                .padding(24)
            }
            .navigationTitle("Focus List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            selectedFilter = .completed
                        } label: {
                            Label("Completed", systemImage: "checkmark.circle")
                        }

                        Button {
                            selectedFilter = .all
                        } label: {
                            Label("Active tasks", systemImage: "list.bullet")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("More filters")
                }
            }
            .sheet(item: $editorRoute) { route in
                TaskEditorView(task: route.task) { task in
                    store.upsert(task)
                    editorRoute = nil
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

private struct TaskEditorRoute: Identifiable {
    let id = UUID()
    let task: TodoTask?
}

private enum TaskListFilter: String, CaseIterable, Identifiable {
    case all
    case today
    case upcoming
    case completed

    static var visibleFilters: [TaskListFilter] {
        [.all, .today, .upcoming]
    }

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .today:
            return "Today"
        case .upcoming:
            return "Upcoming"
        case .completed:
            return "Completed"
        }
    }

    var heading: String {
        switch self {
        case .all:
            return "Tasks"
        case .today:
            return "Today"
        case .upcoming:
            return "Upcoming"
        case .completed:
            return "Completed"
        }
    }

    func contains(_ task: TodoTask) -> Bool {
        switch self {
        case .all:
            return !task.isCompleted
        case .today:
            return !task.isCompleted && task.isDueToday
        case .upcoming:
            return !task.isCompleted && task.isUpcoming
        case .completed:
            return task.isCompleted
        }
    }
}

private struct TaskGroup: Identifiable {
    let title: String
    let tasks: [TodoTask]

    var id: String { title }
}

private struct HeaderView: View {
    let filter: TaskListFilter

    var body: some View {
        Text(filter.heading)
            .font(.system(.caption, design: .rounded).weight(.bold))
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TaskFilterControl: View {
    @Binding var selectedFilter: TaskListFilter

    private var filters: [TaskListFilter] {
        selectedFilter == .completed
            ? TaskListFilter.visibleFilters + [.completed]
            : TaskListFilter.visibleFilters
    }

    var body: some View {
        Picker("Task filter", selection: $selectedFilter) {
            ForEach(filters) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }
}

private struct SearchField: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding var text: String

    private var borderColor: Color {
        colorScheme == .dark ? .white.opacity(0.14) : .white.opacity(0.55)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search tasks, notes, or subtasks", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        }
    }
}

private struct CategoryFilter: View {
    @Binding var selectedCategory: TodoCategory?
    let categories: [TodoCategory]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                CategoryChip(
                    title: "All",
                    symbol: "sparkles",
                    tint: .blue,
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                ForEach(categories) { category in
                    CategoryChip(
                        title: category.title,
                        symbol: category.symbol,
                        tint: category.tint,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private struct TaskSection: View {
    @Environment(\.colorScheme) private var colorScheme

    let groups: [TaskGroup]
    let filter: TaskListFilter
    let searchText: String
    let selectedCategory: TodoCategory?
    let onToggleTask: (TodoTask) -> Void
    let onToggleSubtask: (UUID, UUID) -> Void
    let onEdit: (TodoTask) -> Void
    let onDelete: (TodoTask) -> Void

    private var taskCount: Int {
        groups.reduce(0) { count, group in count + group.tasks.count }
    }

    private var countBackground: Color {
        colorScheme == .dark ? .white.opacity(0.08) : .white.opacity(0.65)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Tasks")
                    .font(.system(.title2, design: .rounded).weight(.bold))

                Spacer()

                Text("\(taskCount)")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(countBackground, in: Capsule())
            }

            if taskCount == 0 {
                EmptyStateView(
                    filter: filter,
                    hasSearchText: !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    selectedCategory: selectedCategory
                )
            } else {
                LazyVStack(alignment: .leading, spacing: 18) {
                    ForEach(groups) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(group.title)
                                    .font(.system(.headline, design: .rounded).weight(.bold))

                                Spacer()

                                Text("\(group.tasks.count)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)
                            }

                            ForEach(group.tasks) { task in
                                TaskRowView(
                                    task: task,
                                    onToggleTask: { onToggleTask(task) },
                                    onToggleSubtask: { subtask in
                                        onToggleSubtask(task.id, subtask.id)
                                    },
                                    onEdit: { onEdit(task) },
                                    onDelete: { onDelete(task) }
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct EmptyStateView: View {
    @Environment(\.colorScheme) private var colorScheme

    let filter: TaskListFilter
    let hasSearchText: Bool
    let selectedCategory: TodoCategory?

    private var title: String {
        if hasSearchText {
            return "No matching tasks"
        }

        switch filter {
        case .all:
            return selectedCategory == nil ? "No active tasks" : "No active \(selectedCategory?.title.lowercased() ?? "") tasks"
        case .today:
            return "Nothing due today"
        case .upcoming:
            return "No upcoming tasks"
        case .completed:
            return "No completed tasks"
        }
    }

    private var message: String {
        if hasSearchText {
            return "Try a different search or category."
        }

        switch filter {
        case .all:
            return "Add a task when something needs your attention."
        case .today:
            return "Tasks with today's due date will appear here."
        case .upcoming:
            return "Future dated tasks will appear here."
        case .completed:
            return "Completed tasks are kept here once you tick them off."
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: filter == .completed ? "checkmark.circle" : "calendar.badge.checkmark")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(
            colorScheme == .dark ? .white.opacity(0.07) : .white.opacity(0.65),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(colorScheme == .dark ? .white.opacity(0.10) : .white.opacity(0.45), lineWidth: 1)
        }
    }
}

private struct AddTaskButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let action: () -> Void

    private var iconColor: Color {
        colorScheme == .dark ? .black : .white
    }

    private var buttonColors: [Color] {
        colorScheme == .dark
            ? [.white, .white.opacity(0.82)]
            : [.black, .black.opacity(0.72)]
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(iconColor)
                .frame(width: 64, height: 64)
                .background(
                    LinearGradient(
                        colors: buttonColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Circle()
                )
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.45 : 0.22), radius: 18, x: 0, y: 12)
        }
        .accessibilityLabel("Add task")
    }
}

#Preview {
    ContentView()
        .environmentObject(TodoStore())
}

private extension TodoTask {
    var isDueToday: Bool {
        guard let dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }

    var isUpcoming: Bool {
        guard let dueDate else { return false }
        return dueDate > Date() && !Calendar.current.isDateInToday(dueDate)
    }

    var hasNoDueDate: Bool {
        dueDate == nil
    }
}
