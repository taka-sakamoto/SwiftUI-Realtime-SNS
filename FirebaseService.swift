//
//  FirebaseService.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/04/30.
//

import Foundation
import FirebaseStorage
import UIKit
import FirebaseFirestore
import PhotosUI
import FirebaseAuth

class FirebaseService {
    
    static let shared = FirebaseService()
    private let starage = Storage.storage()
    private let db = Firestore.firestore()
    
    func createPost(imageUrl: String, userId: String) {
        let data: [String: Any] = [
            "imageUrl": imageUrl,
            "userId": userId,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("posts").addDocument(data: data) { error in
            if let error = error {
                print("Firestore error:", error.localizedDescription)
            } else {
                print("Post saved")
            }
        }
        
    }
    
    func uploadImage(data: Data, uid: String) {
        
        let path = "images/\(uid)/\(UUID().uuidString).jpg"
        let ref = Storage.storage().reference().child(path)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
    
        ref.putData(data) { _, error in
            guard error == nil else { return }
            
            ref.downloadURL { url, error in
                guard let url = url else { return }
                
                let userRef = Firestore.firestore().collection("users").document(uid)
                
                userRef.getDocument { snapshot, _ in
                    let name = snapshot?.data()?["name"] as? String ?? "Unknown"
                    
                    let postData: [String: Any] = [
                        "imageUrl": url.absoluteString,
                        "userId": uid,
                        "userName": name,
                        "imagePath": path,
                        "createdAt": FieldValue.serverTimestamp(),
                        "likedBy": []
                    ]
                    
                    Firestore.firestore().collection("posts").addDocument(data: postData)
                    
                    print("保存成功（userName付き）:", name)
                }
            }
        }
    }
    
    func fetchPosts(completion: @escaping ([Post]) -> Void) {
        Firestore.firestore().collection("posts")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let posts = documents.compactMap { doc -> Post? in
                    let data = doc.data()
                    
                    guard let imageUrl = data["imageUrl"] as? String,
                          let userId = data["userId"] as? String else { return nil }
                    
                    return Post(
                        id: doc.documentID,
                        imageUrl: data["imageUrl"] as? String ?? "",
                        userId: data["userId"] as? String ?? "",
                        userName: data["userName"] as? String ?? "Unknown",
                        imagePath: data["imagePath"] as? String ?? "",
                        createdAt: Date(),
                        likedBy: data["likedBy"] as? [String] ?? []
                    )
                    
                }
                completion(posts) // ← 1回だけ
                
            }
        
    }
    
    func deletePost(post: Post) {
        db.collection("posts").document(post.id).delete()
        
        Firestore.firestore()
            .collection("posts")
            .document(post.id)
            .delete { error in
                if let error = error {
                    print("Firestore削除エラー:", error)
                } else {
                    print("Firesotore削除成功")
                }
            }
        
        // Storage削除(pathベース)
        let ref = Storage.storage().reference(withPath: post.imagePath)
        ref.delete { _ in }
        print("削除対象:", post.imagePath)
    }

    func toggleLike(post: Post) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let ref = Firestore.firestore()
            .collection("posts")
            .document(post.id)
        
        let isLiked = post.likedBy.contains(uid)
        
        ref.updateData([
            "likedBy": isLiked
            ? FieldValue.arrayRemove([uid])
            : FieldValue.arrayUnion([uid])
        ])
    }

}
