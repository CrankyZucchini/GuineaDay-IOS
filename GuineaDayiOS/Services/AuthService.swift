import Foundation
import FirebaseAuth

/// Handles email/password authentication with Firebase Auth.
@Observable
final class AuthService {

    var user: FirebaseAuth.User? = nil
    var isSignedIn: Bool { user != nil }

    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        user = result.user
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        user = result.user
    }

    // MARK: - Sign Out

    func signOut() throws {
        try Auth.auth().signOut()
        user = nil
    }

    // MARK: - Password Reset

    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
}
