//
//  ProfileViewModel.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/05/20.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine
import UIKit

final class ProfileViewModel: ObservableObject {
    
    @Published var posts: [Post] = []
    
    @Published var user: User?
    @Published var isFollowing = false
    @Published var isFollowedBy = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let repository = UserRepository()
    private let imageUploader = ProfileImageUploader()
    
    private var postsListener: ListenerRegistration?
    
    
    func loadUser() async {

        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }

        isLoading = true

        do {
            user = try await repository.fetchUser(uid: uid)

        } catch {
            
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
    
    func updateUser(_ user: User) async {

        do {
            try await repository.updateUser(user)
            self.user = user
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func updateProfile(displayName: String, bio: String) async {
        
        guard var currentUser = user else {
            return
        }
        
        currentUser.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        currentUser.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        currentUser.updatedAt = Date()
        
        do {
            try await repository.updateUser(currentUser)
            
            // 画面へ即反映
            self.user = currentUser
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Fetch Posts
    
    func fetchPosts(userID: String) {
        
        postsListener?.remove()
        postsListener = nil
        
        postsListener = db.collection("posts")
            .whereField("userId", isEqualTo: userID)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                
                guard let self else { return }
                
                if let error {
                    Task { @MainActor in
                        self.errorMessage = error.localizedDescription
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    return
                }
                
                let posts = documents.compactMap { doc -> Post in
                    
                    let data = doc.data()
                    
                    let timestamp = data["createdAt"] as? Timestamp
                    
                    return Post(
                        id: doc.documentID,
                        imageUrl: data["imageUrl"] as? String ?? "",
                        userId: data["userId"] as? String ?? "",
                        userName: data["userName"] as? String ?? "Unknown",
                        imagePath: data["imagePath"] as? String ?? "",
                        caption: data["caption"] as? String ?? "",
                        filterName: data["filterName"] as? String,
                        createdAt: timestamp?.dateValue() ?? Date(),
                        likedBy: data["likedBy"] as? [String] ?? [],
                        commentCount: data["commentCount"] as? Int ?? 0
                    )
                    
                }
                
                Task { @MainActor in
                    self.posts = posts
                    
                }
                
            }
    }
    
    deinit {
        postsListener?.remove()
    }
    
    
    @MainActor
    func updateProfileImage(_ image: UIImage) async {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        do {
            let imageURL = try await imageUploader.upload(
                image: image,
                uid: uid
            )
            
            try await repository.updateProfileImage(
                uid: uid,
                imageURL: imageURL
            )
            
            user?.profileImageURL = imageURL
            user?.updatedAt = Date()
            
        } catch {
            print("Failed to update profile image:", error)
        }
    }
    
    @MainActor
    func loadOrCreateUser() async {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        isLoading = true
        
        do {
            
            // 既存ユーザー取得
            user = try await repository.fetchUser(uid: uid)
            
        } catch {
            
            // 存在しなければ新規作成
            let newUser = User(
                id: uid,
                displayName: "User\(Int.random(in: 1000...9999))",
                bio: "",
                profileImageURL: "",
                createdAt: Date(),
                updatedAt: Date()
            )
            
            do {
                try await repository.createUser(newUser)
                user = newUser
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    @MainActor
    func fetchUser(uid: String) async {
        
        do {
            user = try await repository.fetchUser(uid: uid)
        } catch {
            print("Failed to fetch user: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Follow
    
    @MainActor
    func checkFollowing(targetUserID: String) async {
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        guard currentUserID != targetUserID else {
            isFollowing = false
            isFollowedBy = false
            return
        }
        
        do {
            // 自分 → 相手
            isFollowing = try await repository.isFollowing(
                currentUserID: currentUserID,
                targetUserID: targetUserID
            )
            
            // 相手 → 自分
            isFollowedBy = try await repository.isFollowing(
                currentUserID: targetUserID,
                targetUserID: currentUserID
            )
                
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func follow(targetUserID: String) async {

        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        guard currentUserID != targetUserID else {
            return
        }
        
        do {
            try await repository.followUser(
                currentUserID: currentUserID,
                targetUserID: targetUserID
            )
            
            isFollowing = true
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Unfollow
    
    @MainActor
    func unfollow(targetUserID: String) async {
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        guard currentUserID != targetUserID else {
            return
        }
        
        do {
            try await repository.unfollowUser(
                currentUserID: currentUserID,
                targetUserID: targetUserID
            )
            
            isFollowing = false
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Load Profile
    
    @MainActor
    func loadProfile(userID: String) async {
        
        isLoading = true
        
        do {
            user = try await repository.fetchUser(uid: userID)
            
            fetchPosts(userID: userID)
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Clear User State
    
    func clearUserState() {
        
        postsListener?.remove()
        postsListener = nil
        
        posts = []
        user = nil
        isFollowing = false
        isFollowedBy = false
        isLoading = false
        errorMessage = nil
    }
}
