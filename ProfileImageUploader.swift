//
//  ProfileImageUploader.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/07/02.
//

import Foundation
import UIKit
import FirebaseStorage

final class ProfileImageUploader {
    
    private let storage = Storage.storage()
    
    func upload(
        image: UIImage,
        uid: String
    ) async throws -> String {
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(
                domain: "ProfileImageUploder",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to convert image to JPEG."
                ]
            )
        }
        
        let reference = storage.reference()
            .child("profiles")
            .child("\(uid).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await reference.putDataAsync(imageData, metadata: metadata)
        
        let downloadURL = try await reference.downloadURL()
        
        return downloadURL.absoluteString
    }
}
