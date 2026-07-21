//
//  PostViewModel.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/04/30.
//

import Foundation
import Combine
import Firebase
import FirebaseFirestore
import FirebaseStorage

class PostViewModel: ObservableObject {
    
    @Published var posts: [Post] = []
    
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
                    
                    // createdAt取得（重要）
                    // let timestamp = data["createdAt"] as? Timestamp
                    guard let timestamp = data["createdAt"] as? Timestamp else { return nil }
                    let date = timestamp.dateValue()
                    
                    return Post(
                        id: doc.documentID,
                        imageUrl: data["imageUrl"] as? String ?? "",
                        userId: data["userId"] as? String ?? "",
                        userName: data["userName"] as? String ?? "Unknown",
                        imagePath: data["imagePath"] as? String ?? "",
                        caption: data["caption"] as? String ?? "",
                        filterName: data["filterName"] as? String,
                        createdAt: date,
                        likedBy: data["likedBy"] as? [String] ?? [],
                        commentCount: data["commentCount"] as? Int ?? 0
                    )
                }
                .sorted { $0.createdAt > $1.createdAt }
                
            }
        
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
}
