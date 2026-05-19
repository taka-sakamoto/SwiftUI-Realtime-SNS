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

        private let db = Firestore.firestore()
        private let storage = Storage.storage()
    
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
    
    func uploadImage(data: Data, uid: String, name: String) {
        
        let path = "images/\(uid)/\(UUID().uuidString).jpg"
        let ref = storage.reference().child(path)
        
        ref.putData(data) { _, error in
        
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            ref.downloadURL { url, error in
                guard let url = url else { return }
                
                let postData: [String: Any] = [
                    "imageUrl": url.absoluteString,
                    "userId": uid,
                    "userName": name,
                    "imagePath": path,
                    "createdAt": FieldValue.serverTimestamp(),
                    "likedBy": [],
                    "commentCount": 0
                ]
                self.db.collection("posts").addDocument(data: postData)
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
                        likedBy: data["likedBy"] as? [String] ?? [],
                        commentCount: data["commentCount"] as? Int ?? 0
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
        
        let ref = db.collection("posts").document(post.id)
        
        if post.likedBy.contains(uid) {
            ref.updateData([
                "likedBy": FieldValue.arrayRemove([uid])
            ])
        } else {
            ref.updateData([
                "likedBy": FieldValue.arrayUnion([uid])
            ])
        }
    }
    
    func addComment(
        postId: String,
        text: String,
        uid: String,
        userName: String
    ) {

        let data: [String: Any] = [
            "text": text,
            "userId": uid,
            "userName": userName,
            "createdAt": FieldValue.serverTimestamp()
        ]

        db.collection("posts")
            .document(postId)
            .collection("comments")
            .addDocument(data: data)
        
        db.collection("posts")
            .document(postId)
            .updateData([
                "commentCount": FieldValue.increment(Int64(1))
            ])
    }
    
    func listenComments(
        postId: String,
        completion: @escaping ([Comment]) -> Void
    ) {

        db.collection("posts")
            .document(postId)
            .collection("comments")
            .order(by: "createdAt")

            .addSnapshotListener { snapshot, error in

                guard let documents = snapshot?.documents else {
                    return
                }

                let comments = documents.compactMap { doc -> Comment? in

                    let data = doc.data()

                    let date =
                    (data["createdAt"] as? Timestamp)?
                        .dateValue()
                    ?? Date()

                    return Comment(
                        id: doc.documentID,
                        text: data["text"] as? String ?? "",
                        userId: data["userId"] as? String ?? "",
                        userName: data["userName"] as? String ?? "",
                        createdAt: date
                    )
                }

                completion(comments)
            }
    }
    
    func deleteComment(
        postId: String,
        commentId: String
    ) {
        
        db.collection("posts")
            .document(postId)
            .collection("comments")
            .document(commentId)
            .delete()
        
        db.collection("posts")
            .document(postId)
            .updateData([
                "commentCount": FieldValue.increment(Int64(-1))
            ])
    }
    
}
