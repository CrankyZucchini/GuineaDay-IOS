import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Central real-time data service. Inject via .environment(firestoreService).
/// Replaces @Query + modelContext in all views.
@Observable
final class FirestoreService {

    var pigs: [GuineaPig]      = []
    var tasks: [TaskItem]      = []
    var weightLogs: [WeightLog] = []
    var photos: [Photo]        = []
    var isReady: Bool          = false

    private var householdId: String = ""
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []

    // MARK: - Setup

    func start(householdId: String) {
        guard self.householdId != householdId else { return }
        self.householdId = householdId
        stopListeners()
        attachListeners()
        isReady = true
    }

    func stop() {
        stopListeners()
        pigs = []; tasks = []; weightLogs = []; photos = []
        householdId = ""
        isReady = false
    }

    private func stopListeners() {
        listeners.forEach { $0.remove() }
        listeners = []
    }

    private func col(_ name: String) -> CollectionReference {
        db.collection("households").document(householdId).collection(name)
    }

    // MARK: - Real-time Listeners

    private func attachListeners() {
        listeners.append(col("pigs").addSnapshotListener { [weak self] snap, _ in
            self?.pigs = snap?.documents.compactMap { try? $0.data(as: GuineaPig.self) } ?? []
        })
        listeners.append(col("tasks").order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snap, _ in
                self?.tasks = snap?.documents.compactMap { try? $0.data(as: TaskItem.self) } ?? []
            })
        listeners.append(col("weightLogs").order(by: "date")
            .addSnapshotListener { [weak self] snap, _ in
                self?.weightLogs = snap?.documents.compactMap { try? $0.data(as: WeightLog.self) } ?? []
            })
        // Photos are stored locally now
        loadLocalPhotos()
    }

    // MARK: - Guinea Pigs

    func addPig(_ pig: GuineaPig) throws {
        try col("pigs").document(pig.id).setData(from: pig)
    }

    func updatePig(_ pig: GuineaPig) throws {
        try col("pigs").document(pig.id).setData(from: pig)
    }

    func deletePig(_ pig: GuineaPig) async throws {
        // Delete weight logs belonging to this pig
        let logsToDelete = weightLogs.filter { $0.pigId == pig.id }
        for log in logsToDelete {
            try await col("weightLogs").document(log.id).delete()
        }
        try await col("pigs").document(pig.id).delete()
    }

    // MARK: - Tasks

    func addTask(_ task: TaskItem) throws {
        try col("tasks").document(task.id).setData(from: task)
    }

    func updateTask(_ task: TaskItem) throws {
        try col("tasks").document(task.id).setData(from: task)
    }

    func deleteTask(_ task: TaskItem) async throws {
        try await col("tasks").document(task.id).delete()
    }

    // MARK: - Weight Logs

    func addWeightLog(_ log: WeightLog) throws {
        try col("weightLogs").document(log.id).setData(from: log)
    }

    func deleteWeightLog(_ log: WeightLog) async throws {
        try await col("weightLogs").document(log.id).delete()
    }

    func weightLogs(for pig: GuineaPig) -> [WeightLog] {
        weightLogs.filter { $0.pigId == pig.id }.sorted { $0.date < $1.date }
    }

    // MARK: - Local Photos

    private let photosKey = "gd_local_photos"

    private func loadLocalPhotos() {
        if let data = UserDefaults.standard.data(forKey: photosKey),
           let decoded = try? JSONDecoder().decode([Photo].self, from: data) {
            self.photos = decoded.sorted { $0.dateTaken > $1.dateTaken }
        }
    }

    private func saveLocalPhotos() {
        if let encoded = try? JSONEncoder().encode(photos) {
            UserDefaults.standard.set(encoded, forKey: photosKey)
        }
    }

    func addPhoto(_ photo: Photo) throws {
        photos.append(photo)
        photos.sort { $0.dateTaken > $1.dateTaken }
        saveLocalPhotos()
    }

    func deletePhoto(_ photo: Photo) async throws {
        photos.removeAll { $0.id == photo.id }
        saveLocalPhotos()
    }
}
