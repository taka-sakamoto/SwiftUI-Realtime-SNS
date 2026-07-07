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
    
    // MARK: - Update ProfileImage
    
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
    
    // MARK: - Listen User
    
    func listenUser(
        uid: String,
        onChange: @escaping (User?) -> Void
    ) -> ListenerRegistration {
        
        db.collection("users")
            .document(uid)
            .addSnapshotListener { snapshot, error in
                
                if let error = error {
                    print("Failed to listen user: \(error)")
                    onChange(nil)
                    return
                }
                
                guard
                    let snapshot = snapshot,
                    let data = snapshot.data()
                else {
                    onChange(nil)
                    return
                }
                
                let createdAt = data["createdAt"] as? Timestamp
                let updatedAt = data["updatedAt"] as? Timestamp
                
                let user = User(
                    id: uid,
                    displayName: data["displayName"] as? String ?? "",
                    bio: data["bio"] as? String ?? "",
                    profileImageURL: data["profileImageURL"] as? String ?? "",
                    createdAt: createdAt?.dateValue() ?? Date(),
                    updatedAt: updatedAt?.dateValue() ?? Date()
                )
                
                onChange(user)
                
            }
    }
}
