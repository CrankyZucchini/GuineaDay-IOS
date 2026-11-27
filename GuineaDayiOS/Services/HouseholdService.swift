import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Manages the "household" concept — a shared Firestore namespace both partners read/write to.
/// One user creates a household (gets an invite code), the partner enters the code to join.
@Observable
final class HouseholdService {

    var householdId: String? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil

    private let db = Firestore.firestore()
    private let userDefaults = UserDefaults.standard
    private let householdKey = "gd_householdId"

    init() {
        householdId = userDefaults.string(forKey: householdKey)
    }

    // MARK: - Create a new household

    /// Creates a new household document owned by the current user. Returns the 6-character invite code.
    func createHousehold(uid: String) async throws -> String {
        isLoading = true
        defer { isLoading = false }

        let code = generateCode()
        let ref = db.collection("households").document(code)
        try await ref.setData([
            "inviteCode": code,
            "members": [uid],
            "createdAt": FieldValue.serverTimestamp()
        ])
        // Also write to user's document so we can look it up on next launch
        try await db.collection("users").document(uid).setData(
            ["householdId": code], merge: true
        )
        self.householdId = code
        userDefaults.set(code, forKey: householdKey)
        return code
    }

    // MARK: - Join an existing household

    func joinHousehold(code: String, uid: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let ref = db.collection("households").document(code.uppercased())
        let snap = try await ref.getDocument()
        guard snap.exists else {
            errorMessage = "No household found with code \(code.uppercased())"
            throw HouseholdError.notFound
        }
        // Add self to members array
        try await ref.updateData(["members": FieldValue.arrayUnion([uid])])
        try await db.collection("users").document(uid).setData(
            ["householdId": code.uppercased()], merge: true
        )
        self.householdId = code.uppercased()
        userDefaults.set(code.uppercased(), forKey: householdKey)
    }

    // MARK: - Restore household from Firestore (on new device login)

    func restoreHousehold(uid: String) async {
        guard householdId == nil else { return }
        if let snap = try? await db.collection("users").document(uid).getDocument(),
           let hid = snap.data()?["householdId"] as? String {
            self.householdId = hid
            userDefaults.set(hid, forKey: householdKey)
        }
    }

    // MARK: - Leave household

    func leaveHousehold(uid: String) async throws {
        guard let hid = householdId else { return }
        try await db.collection("households").document(hid)
            .updateData(["members": FieldValue.arrayRemove([uid])])
        try await db.collection("users").document(uid)
            .updateData(["householdId": FieldValue.delete()])
        self.householdId = nil
        userDefaults.removeObject(forKey: householdKey)
    }

    // MARK: - Helpers

    private func generateCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }

    enum HouseholdError: LocalizedError {
        case notFound
        var errorDescription: String? { "Household not found. Check the invite code." }
    }
}
