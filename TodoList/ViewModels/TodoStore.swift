import Foundation
import Combine

@MainActor
final class TodoStore: ObservableObject {
    @Published private(set) var tasks: [TodoTask] = [] {
        didSet {
            persist()
        }
    }

    private let storage = TodoTaskStorage()

    init() {
        load()
    }

    var activeCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }

    var completedCount: Int {
        tasks.filter(\.isCompleted).count
    }

    var dueTodayCount: Int {
        tasks.filter { task in
            guard let dueDate = task.dueDate, !task.isCompleted else { return false }
            return Calendar.current.isDateInToday(dueDate)
        }.count
    }

    func bootstrapNotifications() async {
        await NotificationScheduler.shared.syncReminders(for: tasks)
    }

    func upsert(_ task: TodoTask) {
        var task = task
        task.updatedAt = Date()

        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        } else {
            tasks.insert(task, at: 0)
        }

        Task {
            await NotificationScheduler.shared.syncReminder(for: task)
        }
    }

    func delete(_ task: TodoTask) {
        tasks.removeAll { $0.id == task.id }

        Task {
            await NotificationScheduler.shared.cancelReminder(for: task.id)
        }
    }

    func toggleCompletion(for task: TodoTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }

        tasks[index].isCompleted.toggle()
        tasks[index].completedAt = tasks[index].isCompleted ? Date() : nil
        tasks[index].updatedAt = Date()

        let updatedTask = tasks[index]
        Task {
            await NotificationScheduler.shared.syncReminder(for: updatedTask)
        }
    }

    func toggleSubtask(taskID: UUID, subtaskID: UUID) {
        guard let taskIndex = tasks.firstIndex(where: { $0.id == taskID }),
              let subtaskIndex = tasks[taskIndex].subtasks.firstIndex(where: { $0.id == subtaskID }) else {
            return
        }

        tasks[taskIndex].subtasks[subtaskIndex].isCompleted.toggle()
        tasks[taskIndex].updatedAt = Date()
    }

    func filteredTasks(
        in category: TodoCategory?,
        searchText: String,
        includeCompleted: Bool
    ) -> [TodoTask] {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return tasks
            .filter { task in
                if let category, task.category != category {
                    return false
                }

                if !includeCompleted && task.isCompleted {
                    return false
                }

                guard !normalizedSearch.isEmpty else {
                    return true
                }

                let searchableText = ([task.title, task.notes] + task.subtasks.map(\.title))
                    .joined(separator: " ")
                    .lowercased()

                return searchableText.contains(normalizedSearch)
            }
            .sorted(by: sortTasks)
    }

    private func sortTasks(_ lhs: TodoTask, _ rhs: TodoTask) -> Bool {
        if lhs.isCompleted != rhs.isCompleted {
            return !lhs.isCompleted
        }

        if lhs.priority.sortRank != rhs.priority.sortRank {
            return lhs.priority.sortRank < rhs.priority.sortRank
        }

        switch (lhs.dueDate, rhs.dueDate) {
        case let (left?, right?):
            return left < right
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            return lhs.createdAt > rhs.createdAt
        }
    }

    private func load() {
        tasks = storage.loadTasks()
    }

    private func persist() {
        storage.saveTasks(tasks)
    }
}
