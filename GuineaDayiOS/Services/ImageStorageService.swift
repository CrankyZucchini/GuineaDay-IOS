import Foundation
import UIKit
import FirebaseStorage

/// Firebase Storage-backed image service.
/// Replaces the local FileManager version.
final class ImageStorageService {
    static let shared = ImageStorageService()
    private init() {}

    private let storage = Storage.storage()
    private var householdId: String = ""

    func configure(householdId: String) {
        self.householdId = householdId
    }

    private func ref(filename: String) -> StorageReference {
        storage.reference()
            .child("households/\(householdId)/images/\(filename)")
    }

    // MARK: - Upload

    /// Uploads a UIImage to Firebase Storage and returns the download URL string.
    func uploadImage(_ image: UIImage, name: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw ImageError.compressionFailed
        }
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        let r = ref(filename: name)
        _ = try await r.putDataAsync(data, metadata: meta)
        let url = try await r.downloadURL()
        return url.absoluteString
    }

    // MARK: - Load (cached in memory)

    private var cache: [String: UIImage] = [:]

    func loadImage(url: String) async -> UIImage? {
        if let cached = cache[url] { return cached }
        guard let u = URL(string: url),
              let (data, _) = try? await URLSession.shared.data(from: u),
              let img = UIImage(data: data) else { return nil }
        cache[url] = img
        return img
    }

    // MARK: - Delete

    func deleteImage(name: String) async {
        try? await ref(filename: name).delete()
    }

    enum ImageError: LocalizedError {
        case compressionFailed
        var errorDescription: String? { "Could not compress image." }
    }
}
