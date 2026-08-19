//
//  ImageListViewModel.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/05/01.
//

import Foundation
import FirebaseStorage
import Combine
import UIKit
import FirebaseFirestore
import FirebaseAuth

class ImageListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var posts: [Post] = []
    
    @Published var users: [String: User] = [:]
    
    @Published var savedPostIDs: Set<String> = []
    
    @Published var savedPosts: [Post] = []
    
    private var isLoading = false
    
    private var listener: ListenerRegistration?
    
    // MARK: - Dependencies
    
    private let userRepository = UserRepository()
    
    private var userListeners: [String: ListenerRegistration] = [:]
    
    // MARK: - Initializer
    
    init() {
        
        Task {
            
            await fetchSavedPostIDs()
            
            await MainActor.run {
                self.updateSavedPosts()
            }
        }
    }
    
    // MARK: Public Methods
    
    @MainActor
    func fetchUserIfNeeded(uid: String) async {
        
        guard users[uid] == nil else {
            return
        }
        
        do {
            
            let user = try await userRepository.fetchUser(uid: uid)
            
            users[uid] = user
            
        } catch {
            
            print("Failed to fetch user:", error)
        }
    }
    
    
    func listenUser(uid: String) {

        guard userListeners[uid] == nil else {
            return
        }

        let listener = userRepository.listenUser(uid: uid) { [weak self] user in

            guard let self else { return }

            Task { @MainActor in
                self.users[uid] = user
            }
        }

        userListeners[uid] = listener
        
    }
    
    func startListening() {
        guard listener == nil else { return }
        
        listener = Firestore.firestore()
            .collection("posts")
            .addSnapshotListener { [weak self] snapshot, error in
                
                guard let self = self else { return }
                guard let documents = snapshot?.documents else { return }
                
                self.posts = documents.compactMap { doc -> Post? in
                    let data = doc.data()
                    
                    guard let timestamp = data["createdAt"] as? Timestamp else {
                        return nil
                    }
                    
                    return Post(
                        id: doc.documentID,
                        imageUrl: data["imageUrl"] as? String ?? "",
                        userId: data["userId"] as? String ?? "",
                        userName: data["userName"] as? String ?? "Unknown",
                        imagePath: data["imagePath"] as? String ?? "",
                        caption: data["caption"] as? String ?? "",
                        filterName: data["filterName"] as? String,
                        createdAt: timestamp.dateValue(),
                        likedBy: data["likedBy"] as? [String] ?? [],
                        commentCount: data["commentCount"] as? Int ?? 0
                    )
                }
                .sorted { $0.createdAt > $1.createdAt }
                
                self.updateSavedPosts()
                
                for post in self.posts {
                    self.listenUser(uid: post.userId)
                    
                }
                
            }
        
    }
    

    func fetchPosts() {
        guard !isLoading else { return }
        isLoading = true
        
        FirebaseService.shared.fetchPosts { posts in
            DispatchQueue.main.async {
                self.posts = posts
                self.isLoading = false
                
            }
        }
    }
    
    func uploadImage(data: Data, uid: String, name: String) {
        FirebaseService.shared.uploadImage(data: data, uid: uid, name: name)
    }
    
    func deletePost(post: Post) {
        FirebaseService.shared.deletePost(post: post)
    }
    
    func toggleLike(post: Post) {
        FirebaseService.shared.toggleLike(post: post)
    }
    
    deinit {
        listener?.remove()
        
        userListeners.values.forEach {
            $0.remove()
        }
    }
    
    @MainActor
    func fetchSavedPostIDs() async {
        
        do {

            savedPostIDs = try await FirebaseService.shared.fetchSavedPostIDs()
            
            updateSavedPosts()

        } catch {
            
            print("Faild to fetch saved posts:", error)
        }
        
    }
    
    @MainActor
    func toggleSave(post: Post) async {
        
        let postId = post.id
        
        do {
            
            let isSaved = savedPostIDs.contains(postId)
            
            try await FirebaseService.shared.toggleSave(
                postId: postId,
                isSaved: isSaved
            )
            
            if isSaved {
                
                savedPostIDs.remove(postId)
                
            } else {
                
                savedPostIDs.insert(postId)
                
            }
            
            updateSavedPosts()
            
        } catch {
            
            print("Failed to toggle save:", error)
        }
    }
    
    
    // MARK: - Private Methods
    
    private func updateSavedPosts() {
        
        /*
        print("UPDATE SAVED")  // ログ用
        print("savedPostIDs:", savedPostIDs)  // ログ用
        print("posts:", posts.map { $0.id })  // ログ用
        */
        
        savedPosts = posts.filter { post in
            
            savedPostIDs.contains(post.id)
        }
        
        // print("savedPosts:", savedPosts.map { $0.id })  // ログ用
        
    }
    
    
}

