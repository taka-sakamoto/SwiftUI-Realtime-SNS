//
//  UserRepository.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/07/01.
//

import Foundation
import FirebaseFirestore

final class UserRepository {
    
    private let db = Firestore.firestore()
    private let collection = "users"
    
    // MARK: - Fetch User
    
    func fetchUser(uid: String) async throws -> User {
        
        let document = try await db
            .collection(collection)
            .document(uid)
            .getDocument()
        
        guard let data = document.data() else {
            throw NSError(
                domain: "UserRepository",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "User not found"]
            )
        }
        
        let timestamp = data["createdAt"] as? Timestamp
        let updatedTimeStamp = data["updatedAt"] as? Timestamp
        
        return User(
            id: uid,
            displayName: data["displayName"] as? String ?? "",
            bio: data["bio"] as? String ?? "",
            profileImageURL: data["profileImageURL"] as? String ?? "",
            createdAt: timestamp?.dateValue() ?? Date(),
            updatedAt: updatedTimeStamp?.dateValue() ?? Date()
        )
        
        return try document.data(as: User.self)
    }
    
    // MARK: - Create User
    
    func createUser(_ user: User) async throws {
        try await db
            .collection(collection)
            .document(user.id)
            .setData([
                "displayName": user.displayName,
                "bio": user.bio,
                "profileImageURL": user.profileImageURL,
                "createdAt": user.createdAt,
                "updatedAt": user.updatedAt
            ])
    }
    
    // MARK: - Update User
    
    func updateUser(_ user: User) async throws {
        try await db
            .collection(collection)
            .document(user.id)
            .setData([
                "displayName": user.displayName,
                "bio": user.bio,
                "profileImageURL": user.profileImageURL,
                "createdAt": user.createdAt,
                "updatedAt": user.updatedAt
            ], merge: true)
    }
    
    func updateProfileImage(
        uid: String,
        imageURL: String
    ) async throws {
        
        let data: [String: Any] = [
            "profileImageURL": imageURL,
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await db
            .collection("users")
            .document(uid)
            .updateData(data)
    }
}
