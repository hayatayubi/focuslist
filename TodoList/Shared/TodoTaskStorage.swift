import Foundation

struct TodoTaskStorage {
    static let storageKey = "focuslist.tasks.v1"

    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    func loadTasks() -> [TodoTask] {
        guard let data = defaults.data(forKey: Self.storageKey) else {
            return []
        }

        return (try? decoder.decode([TodoTask].self, from: data)) ?? []
    }

    func saveTasks(_ tasks: [TodoTask]) {
        guard let data = try? encoder.encode(tasks) else {
            return
        }

        defaults.set(data, forKey: Self.storageKey)
    }
}
