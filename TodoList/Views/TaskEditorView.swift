import SwiftUI
import UniformTypeIdentifiers

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss

    private let existingTask: TodoTask?
    private let onSave: (TodoTask) -> Void

    @State private var title: String
    @State private var notes: String
    @State private var category: TodoCategory
    @State private var priority: TodoPriority
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var hasReminder: Bool
    @State private var reminderDate: Date
    @State private var subtasks: [TodoSubtask]
    @State private var newSubtaskTitle = ""
    @State private var draggedSubtaskID: UUID?

    init(task: TodoTask?, onSave: @escaping (TodoTask) -> Void) {
        self.existingTask = task
        self.onSave = onSave

        _title = State(initialValue: task?.title ?? "")
        _notes = State(initialValue: task?.notes ?? "")
        _category = State(initialValue: task?.category ?? .home)
        _priority = State(initialValue: task?.priority ?? .medium)
        _hasDueDate = State(initialValue: task?.dueDate != nil)
        _dueDate = State(initialValue: task?.dueDate ?? Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        _hasReminder = State(initialValue: task?.reminderDate != nil)
        _reminderDate = State(initialValue: task?.reminderDate ?? Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date())
        _subtasks = State(initialValue: task?.subtasks ?? [])
    }

    private var isEditing: Bool {
        existingTask != nil
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isReminderInvalid: Bool {
        hasReminder && reminderDate < Date().addingTimeInterval(60)
    }

    private var canSave: Bool {
        !trimmedTitle.isEmpty && !isReminderInvalid
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Task name", text: $title)
                        .font(.headline)

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Organise") {
                    Picker("Category", selection: $category) {
                        ForEach(TodoCategory.allCases) { category in
                            Label(category.title, systemImage: category.symbol)
                                .tag(category)
                        }
                    }

                    PrioritySelector(priority: $priority)
                }

                Section("Schedule") {
                    Toggle("Due date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker(
                            "Due",
                            selection: $dueDate,
                            displayedComponents: [.date]
                        )
                    }

                    Toggle("Reminder", isOn: $hasReminder)

                    if hasReminder {
                        DatePicker(
                            "Remind me",
                            selection: $reminderDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )

                        if isReminderInvalid {
                            Text("Choose a reminder at least one minute from now.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

                Section {
                    ForEach($subtasks) { $subtask in
                        HStack(spacing: 10) {
                            Button {
                                subtask.isCompleted.toggle()
                            } label: {
                                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                            }
                            .buttonStyle(.plain)

                            TextField("Subtask", text: $subtask.title)

                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(.secondary)
                                .contentShape(Rectangle())
                                .onDrag {
                                    draggedSubtaskID = subtask.id
                                    return NSItemProvider(object: subtask.id.uuidString as NSString)
                                }
                        }
                        .onDrop(
                            of: [UTType.text],
                            delegate: SubtaskDropDelegate(
                                targetSubtask: subtask,
                                subtasks: $subtasks,
                                draggedSubtaskID: $draggedSubtaskID
                            )
                        )
                    }
                    .onDelete { offsets in
                        subtasks.remove(atOffsets: offsets)
                    }

                    HStack {
                        TextField("Add subtask", text: $newSubtaskTitle)

                        Button("Add") {
                            addSubtask()
                        }
                        .disabled(newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } header: {
                    Text("Subtasks")
                } footer: {
                    Text("Drag the handle to reorder. Swipe left to remove.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppBackground())
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func addSubtask() {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        subtasks.append(TodoSubtask(title: trimmed))
        newSubtaskTitle = ""
    }

    private func save() {
        let cleanedSubtasks = subtasks
            .map { subtask in
                TodoSubtask(
                    id: subtask.id,
                    title: subtask.title.trimmingCharacters(in: .whitespacesAndNewlines),
                    isCompleted: subtask.isCompleted
                )
            }
            .filter { !$0.title.isEmpty }

        let task = TodoTask(
            id: existingTask?.id ?? UUID(),
            title: trimmedTitle,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            priority: priority,
            dueDate: hasDueDate ? Calendar.current.startOfDay(for: dueDate) : nil,
            reminderDate: hasReminder ? reminderDate : nil,
            subtasks: cleanedSubtasks,
            isCompleted: existingTask?.isCompleted ?? false,
            createdAt: existingTask?.createdAt ?? Date(),
            updatedAt: Date(),
            completedAt: existingTask?.completedAt
        )

        onSave(task)
        dismiss()
    }
}

#Preview {
    TaskEditorView(task: TodoTask.samples[0]) { _ in }
}

private struct PrioritySelector: View {
    @Binding var priority: TodoPriority

    var body: some View {
        HStack(spacing: 10) {
            ForEach(TodoPriority.allCases) { option in
                Button {
                    priority = option
                } label: {
                    Text(option.title)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(priority == option ? .white : option.color)
                        .background(
                            priority == option ? option.color : option.color.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(option.color.opacity(priority == option ? 0 : 0.35), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct SubtaskDropDelegate: DropDelegate {
    let targetSubtask: TodoSubtask
    @Binding var subtasks: [TodoSubtask]
    @Binding var draggedSubtaskID: UUID?

    func dropEntered(info: DropInfo) {
        guard let draggedSubtaskID,
              draggedSubtaskID != targetSubtask.id,
              let fromIndex = subtasks.firstIndex(where: { $0.id == draggedSubtaskID }),
              let toIndex = subtasks.firstIndex(where: { $0.id == targetSubtask.id }) else {
            return
        }

        withAnimation {
            subtasks.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedSubtaskID = nil
        return true
    }
}
