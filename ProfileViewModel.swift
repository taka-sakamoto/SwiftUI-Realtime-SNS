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
    
    func fetchMyPosts() {
        
        guard postsListener == nil else { return }
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        postsListener = db.collection("posts")
            .whereField("userId", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                
                guard let self else { return }
                guard let documents = snapshot?.documents else { return }
                
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
                    print("Profile posts updated:", self.posts.count)
                    
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
}
