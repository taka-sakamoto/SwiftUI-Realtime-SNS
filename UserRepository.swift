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
        
        let followersCount = data["followersCount"] as? Int ?? 0
        let followingCount = data["followingCount"] as? Int ?? 0
        
        return User(
            id: uid,
            displayName: data["displayName"] as? String ?? "",
            bio: data["bio"] as? String ?? "",
            profileImageURL: data["profileImageURL"] as? String ?? "",
            followersCount: data["followersCount"] as? Int ?? 0,
            followingCount: data["followingCount"] as? Int ?? 0,
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
                "displayNameLower": user.displayName.lowercased(),
                "bio": user.bio,
                "profileImageURL": user.profileImageURL,
                "followersCount": 0,
                "followingCount": 0,
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
                "displayNameLower": user.displayName.lowercased(),
                "bio": user.bio,
                "profileImageURL": user.profileImageURL,
                // "createdAt": user.createdAt,
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
    
    // MARK: - Create
    
    func savePost(
        uid: String,
        postId: String
    ) async throws {
        
        try await db
            .collection("users")
            .document(uid)
            .collection("savedPosts")
            .document(postId)
            .setData([
                "postId": postId,
                "savedAt": Timestamp()
            ])
    }
    
    // MARK: - Delete
    
    func unsavePost(
        uid: String,
        postId: String
    ) async throws {
        
        try await db
            .collection("users")
            .document(uid)
            .collection("savedPosts")
            .document(postId)
            .delete()
    }
    
    // MARK: - Read
    
    func fetchSavedPostIDs(
        uid: String
    ) async throws -> Set<String> {
        
        let snapshot = try await db
            .collection("users")
            .document(uid)
            .collection("savedPosts")
            .getDocuments()
        
        return Set(
            snapshot.documents.compactMap {
                $0.documentID
            }
        )
    }

    // MARK: - Follow

    func followUser(
        currentUserID: String,
        targetUserID: String
    ) async throws {
        
        guard currentUserID != targetUserID else {
            return
        }
        
        let currentUserRef = db
            .collection(collection)
            .document(currentUserID)
        
        let targetUserRef = db
            .collection(collection)
            .document(targetUserID)
        
        let followingRef = currentUserRef
            .collection("following")
            .document(targetUserID)
        
        let followerRef = targetUserRef
            .collection("followers")
            .document(currentUserID)
        
        try await db.runTransaction { transaction, errorPointer in
            
            let followingSnapshot: DocumentSnapshot
            
            do {
                followingSnapshot = try transaction.getDocument(followingRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            // すでにFollow済みなら何もしない
            if followingSnapshot.exists {
                return nil
            }
            
            transaction.setData(
                [
                    "createdAt": Timestamp()
                ],
                forDocument: followingRef
            )
            
            transaction.setData(
                [
                    "createdAt": Timestamp()
                ],
                forDocument: followerRef
            )
            
            transaction.updateData(
                [
                    "followingCount": FieldValue.increment(Int64(1))
                ],
                forDocument: currentUserRef
            )
            
            transaction.updateData(
                [
                    "followersCount": FieldValue.increment(Int64(1))
                ],
                forDocument: targetUserRef
            )
            
            return nil
        }
    }
    
    // MARK: - Unfollow
    
    func unfollowUser(
        currentUserID: String,
        targetUserID: String
    ) async throws {
        
        guard currentUserID != targetUserID else {
            return
        }
        
        let currentUserRef = db
            .collection(collection)
            .document(currentUserID)
        
        let targetUserRef = db
            .collection(collection)
            .document(targetUserID)
        
        let followingRef = currentUserRef
            .collection("following")
            .document(targetUserID)
        
        let followerRef = targetUserRef
            .collection("followers")
            .document(currentUserID)
        
        try await db.runTransaction { transaction, errorPointer in
            
            let followingSnapshot: DocumentSnapshot
            
            do {
                followingSnapshot = try transaction.getDocument(followingRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            // Followしていなければ何もしない
            guard followingSnapshot.exists else {
                return nil
            }
            
            transaction.deleteDocument(followingRef)
            transaction.deleteDocument(followerRef)
            
            transaction.updateData(
                [
                    "followingCount": FieldValue.increment(Int64(-1))
                ],
                forDocument: currentUserRef
            )
            
            transaction.updateData(
                [
                    "followersCount": FieldValue.increment(Int64(-1))
                ],
                forDocument: targetUserRef
            )
            
            return nil
        }
    }
    
    // MARK: - Check Following
    
    func isFollowing(
        currentUserID: String,
        targetUserID: String
    ) async throws -> Bool {
        
        guard currentUserID != targetUserID else {
            return false
        }
        
        let document  = try await db
            .collection(collection)
            .document(currentUserID)
            .collection("following")
            .document(targetUserID)
            .getDocument()
        
        return document.exists
    }
    
    // MARK: - Follow Lists
    
    func fetchFollowingUserIDs(userID: String) async throws -> [String] {
        
        let snapshot = try await db
            // .collection(collection)
            // .document(userID)
            // .collection("following")
            .collection("users")
            .whereField("displayNameLower", isEqualTo: "user7217")
            .getDocuments()
        
        return snapshot.documents.map { $0.documentID }
    }
    
    func fetchFollowerUserIDs(userID: String) async throws -> [String] {
        
        let snapshot = try await db
            .collection(collection)
            .document(userID)
            .collection("followers")
            .getDocuments()
        
        return snapshot.documents.map { $0.documentID }
    }
    
    // MARK: - Search Users
    
    func searchUsers(keyword: String) async throws -> [User] {
        
        let snapshot = try await db
            .collection("users")
            .order(by: "displayNameLower")
            .start(at: [keyword])
            .end(at: [keyword + "\u{f8ff}"])
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            
            do {
                var data = document.data()
                data["id"] = document.documentID
                
                return try Firestore.Decoder().decode(User.self, from: data)
            } catch {
                print("USER DECODE ERROR:", error)  // ログ用
                return nil
            }
        }
    }
     
}
