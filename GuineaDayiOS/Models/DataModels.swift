import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Firestore-backed plain Codable models (replaces SwiftData @Model classes)

struct GuineaPig: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var birthDate: Date
    var breed: String
    var gender: String
    var profileImageURL: String?   // Firebase Storage download URL

    init(name: String, birthDate: Date, breed: String, gender: String) {
        self.name = name; self.birthDate = birthDate
        self.breed = breed; self.gender = gender
    }
}

struct TaskItem: Codable, Identifiable {
    var id: String = UUID().uuidString
    var title: String
    var dueDate: Date
    var isCompleted: Bool = false
    var category: String
    var priority: String
    var createdAt: Date = Date()
    var completedAt: Date?

    init(title: String, dueDate: Date, category: String, priority: String) {
        self.title = title; self.dueDate = dueDate
        self.category = category; self.priority = priority
    }
}

struct WeightLog: Codable, Identifiable {
    var id: String = UUID().uuidString
    var pigId: String          // references GuineaPig.id
    var date: Date
    var weightGrams: Int

    init(pigId: String, date: Date, weightGrams: Int) {
        self.pigId = pigId; self.date = date; self.weightGrams = weightGrams
    }
}

struct Photo: Codable, Identifiable {
    var id: String = UUID().uuidString
    var storageURL: String     // Firebase Storage download URL
    var dateTaken: Date = Date()

    init(storageURL: String) { self.storageURL = storageURL }
}
