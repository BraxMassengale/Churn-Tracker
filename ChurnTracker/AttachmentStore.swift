import Foundation
import PhotosUI
import SwiftUI

final class AttachmentStore {
    static let shared = AttachmentStore()

    private init() {}

    func importAttachment(from item: PhotosPickerItem, for offer: ChurnOffer) async throws -> OfferAttachment? {
        guard let data = try await item.loadTransferable(type: Data.self) else {
            return nil
        }

        let directory = try attachmentsDirectory()
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = directory.appendingPathComponent(fileName)

        try data.write(to: fileURL, options: .atomic)

        return OfferAttachment(
            fileName: fileName,
            localPath: fileURL.path,
            caption: offer.displayName,
            offer: offer
        )
    }

    private func attachmentsDirectory() throws -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = base.appendingPathComponent("Attachments", isDirectory: true)

        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }

        return directory
    }
}
