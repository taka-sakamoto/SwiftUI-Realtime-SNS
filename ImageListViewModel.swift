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
    @Published var posts: [Post] = []
    
    private var isLoading = false
    
    private var listener: ListenerRegistration?
    
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
                        createdAt: timestamp.dateValue(),
                        likedBy: data["likedBy"] as? [String] ?? []
                    )
                }
                .sorted { $0.createdAt > $1.createdAt }
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
    
    func uploadImage(data: Data, uid: String) {
        FirebaseService.shared.uploadImage(data: data, uid: uid)
        print("Firestore保存")
    }
    
    func deletePost(post: Post) {
        FirebaseService.shared.deletePost(post: post)
    }
    
    func toggleLike(post: Post) {
        FirebaseService.shared.toggleLike(post: post)
    }
}

