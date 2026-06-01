import SwiftUI

struct TaskRowView: View {
    @Environment(\.colorScheme) private var colorScheme

    let task: TodoTask
    let onToggleTask: () -> Void
    let onToggleSubtask: (TodoSubtask) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var priorityColor: Color {
        task.priority.color
    }

    private var priorityBackgroundOpacity: Double {
        colorScheme == .dark ? 0.16 : 0.07
    }

    private var subtaskBackgroundOpacity: Double {
        colorScheme == .dark ? 0.16 : 0.08
    }

    private var cardSurface: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground).opacity(0.92) : .white.opacity(0.82)
    }

    private var menuSurface: Color {
        colorScheme == .dark ? .white.opacity(0.10) : .white.opacity(0.85)
    }

    private var cardStroke: Color {
        priorityColor.opacity(colorScheme == .dark ? 0.42 : 0.28)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Button(action: onToggleTask) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(task.isCompleted ? priorityColor : priorityColor.opacity(0.75))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(task.isCompleted ? "Mark incomplete" : "Mark complete")

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Label(task.category.title, systemImage: task.category.symbol)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(task.category.tint)

                        Spacer(minLength: 8)

                        Label(task.priority.title, systemImage: task.priority.symbol)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(priorityColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(priorityColor.opacity(0.12), in: Capsule())
                    }

                    Text(task.title)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .strikethrough(task.isCompleted, color: .secondary)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)

                    if !task.notes.isEmpty {
                        Text(task.notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }

            if !task.subtasks.isEmpty {
                VStack(spacing: 9) {
                    ProgressView(value: task.progress)
                        .tint(priorityColor)

                    ForEach(task.subtasks) { subtask in
                        Button {
                            onToggleSubtask(subtask)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: subtask.isCompleted ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(subtask.isCompleted ? priorityColor : .secondary)

                                Text(subtask.title)
                                    .font(.subheadline)
                                    .foregroundStyle(subtask.isCompleted ? .secondary : .primary)
                                    .strikethrough(subtask.isCompleted)

                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
                .background(priorityColor.opacity(subtaskBackgroundOpacity), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            HStack(spacing: 10) {
                if let dueDate = task.dueDate {
                    DateBadge(
                        title: task.isOverdue ? "Overdue" : "Due",
                        date: dueDate,
                        color: task.isOverdue ? .red : .orange
                    )
                }

                if let reminderDate = task.reminderDate {
                    DateBadge(title: "Reminder", date: reminderDate, color: .blue)
                }

                Spacer()

                Menu {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                        .background(menuSurface, in: Circle())
                }
            }
        }
        .padding(18)
        .background(priorityColor.opacity(priorityBackgroundOpacity), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .background(cardSurface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(priorityColor)
                .frame(width: 5)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(cardStroke, lineWidth: 1)
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.28 : 0.06), radius: 18, x: 0, y: 10)
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onTapGesture(perform: onEdit)
    }
}

private struct DateBadge: View {
    let title: String
    let date: Date
    let color: Color

    var body: some View {
        Label {
            Text("\(title) \(date.formatted(date: .abbreviated, time: .shortened))")
        } icon: {
            Image(systemName: title == "Reminder" ? "bell.fill" : "calendar")
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(color)
        .lineLimit(1)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(color.opacity(0.12), in: Capsule())
    }
}

#Preview {
    TaskRowView(
        task: TodoTask.samples[0],
        onToggleTask: {},
        onToggleSubtask: { _ in },
        onEdit: {},
        onDelete: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
