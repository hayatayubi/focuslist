import Foundation
import SwiftUI

enum TodoPriority: String, CaseIterable, Codable, Identifiable, Sendable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        }
    }

    var symbol: String {
        switch self {
        case .low:
            return "arrow.down.circle.fill"
        case .medium:
            return "minus.circle.fill"
        case .high:
            return "exclamationmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }

    var sortRank: Int {
        switch self {
        case .high:
            return 0
        case .medium:
            return 1
        case .low:
            return 2
        }
    }
}

enum TodoCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case work
    case home

    var id: String { rawValue }

    var title: String {
        switch self {
        case .work:
            return "Work"
        case .home:
            return "Home"
        }
    }

    var symbol: String {
        switch self {
        case .work:
            return "briefcase.fill"
        case .home:
            return "house.fill"
        }
    }

    var tint: Color {
        switch self {
        case .work:
            return .indigo
        case .home:
            return .teal
        }
    }
}

struct TodoSubtask: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var title: String
    var isCompleted: Bool

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

struct TodoTask: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var title: String
    var notes: String
    var category: TodoCategory
    var priority: TodoPriority
    var dueDate: Date?
    var reminderDate: Date?
    var subtasks: [TodoSubtask]
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        category: TodoCategory = .home,
        priority: TodoPriority = .medium,
        dueDate: Date? = nil,
        reminderDate: Date? = nil,
        subtasks: [TodoSubtask] = [],
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.category = category
        self.priority = priority
        self.dueDate = dueDate
        self.reminderDate = reminderDate
        self.subtasks = subtasks
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
    }

    var completedSubtaskCount: Int {
        subtasks.filter(\.isCompleted).count
    }

    var progress: Double {
        guard !subtasks.isEmpty else {
            return isCompleted ? 1 : 0
        }

        return Double(completedSubtaskCount) / Double(subtasks.count)
    }

    var isOverdue: Bool {
        guard let dueDate else { return false }
        return !isCompleted && dueDate < Date()
    }

    var hasFutureReminder: Bool {
        guard let reminderDate else { return false }
        return !isCompleted && reminderDate > Date()
    }
}

extension TodoTask {
    static let samples: [TodoTask] = [
        TodoTask(
            title: "Prepare sprint plan",
            notes: "Review backlog, confirm scope, and share priorities.",
            category: .work,
            priority: .high,
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            subtasks: [
                TodoSubtask(title: "Review backlog", isCompleted: true),
                TodoSubtask(title: "Confirm estimates"),
                TodoSubtask(title: "Send plan")
            ]
        ),
        TodoTask(
            title: "Reset hallway storage",
            notes: "Donate what is unused and label remaining boxes.",
            category: .home,
            priority: .low,
            subtasks: [
                TodoSubtask(title: "Sort boxes"),
                TodoSubtask(title: "Create donation bag")
            ]
        )
    ]
}
