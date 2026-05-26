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

final class ProfileViewModel: ObservableObject {
    
    @Published var posts: [Post] = []
    
    private let db = Firestore.firestore()
    
    func fetchMyPosts() {
        
        guard let uid = Auth.auth().currentUser?.uid
        else { return }
        
        db.collection("posts")
            .whereField("userId", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                
                guard let documents = snapshot?.documents
                else { return }
                
                self.posts = documents.compactMap { doc in
                    
                    let data = doc.data()
                    
                    let timestamp =
                    data["createdAt"] as? Timestamp
                    
                    let date =
                    timestamp?.dateValue() ?? Date()
                    
                    return Post(
                        id: doc.documentID,
                        imageUrl: data["imageUrl"] as? String ?? "",
                        userId: data["userId"] as? String ?? "",
                        userName: data["userName"] as? String ?? "",
                        imagePath: data["imagePath"] as? String ?? "",
                        filterName: data["filterName"] as? String,
                        createdAt: date,
                        likedBy: data["likedBy"] as? [String] ?? [],
                        commentCount: data["commentCount"] as? Int ?? 0
                    )
                }
                
            }
    }
}
