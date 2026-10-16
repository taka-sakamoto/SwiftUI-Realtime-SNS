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
    
    private let userRepository = UserRepository()
    
    func createPost(imageUrl: String, userId: String) {
        let data: [String: Any] = [
            "imageUrl": imageUrl,
            "userId": userId,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("posts").addDocument(data: data) { error in
            if error != nil {
                return
            }
        }
        
    }
    
    func uploadImage(data: Data, uid: String, name: String) {
        
        let path = "images/\(uid)/\(UUID().uuidString).jpg"
        let ref = storage.reference().child(path)
        
        ref.putData(data) { _, error in
        
            if error != nil {
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
                    
                    return Post(
                        id: doc.documentID,
                        imageUrl: data["imageUrl"] as? String ?? "",
                        userId: data["userId"] as? String ?? "",
                        userName: data["userName"] as? String ?? "Unknown",
                        imagePath: data["imagePath"] as? String ?? "",
                        caption: data["caption"] as? String ?? "",
                        filterName: data["filterName"] as? String,
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
               
            }
        
        // Storage削除(pathベース)
        let ref = Storage.storage().reference(withPath: post.imagePath)
        ref.delete { _ in }
        
    }
    
    func toggleLike(post: Post) async {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = db.collection("posts").document(post.id)
        
        if post.likedBy.contains(uid) {
            do {
                try await ref.updateData([
                    "likedBy": FieldValue.arrayRemove([uid])
                ])
            } catch {
                print("Umlike failed:", error.localizedDescription)
            }
        } else {
            do {
                try await ref.updateData([
                    "likedBy": FieldValue.arrayUnion([uid])
                ])
                
                // 自分の投稿へのいいねでは通知しない
                guard post.userId != uid else {
                    return
                }
                
                try await userRepository.createNotification(
                    recipientID: post.userId,
                    senderID: uid,
                    type: .like,
                    postID: post.id
                )
                
                print("Like notification created successfully")
                
            } catch {
                print("Like or notification failed:", error.localizedDescription)
            }
        }
    }
    
    func addComment(
        postId: String,
        text: String,
        uid: String,
        userName: String,
        profileImageURL: String
    ) {

        let data: [String: Any] = [
            "text": text,
            "userId": uid,
            "userName": userName,
            "profileImageURL": profileImageURL,
            "createdAt": FieldValue.serverTimestamp()
        ]

        // コメントを保存
        self.db.collection("posts")
            .document(postId)
            .collection("comments")
            .addDocument(data: data) { error in  // ログ用
                if let error = error {
                    print("Comment save failed:", error.localizedDescription)
                    return
                }
                
                print("Comment saved successfully")  // ログ用
                
                // コメント保存後に通知を作成
                Task {
                    do {
                        let postSnapshot = try await self.db
                            .collection("posts")
                            .document(postId)
                            .getDocument()
                        
                        guard let postData = postSnapshot.data(),
                              let postOwnerID = postData["userId"] as? String
                        else {
                            print("Comment notification failed: post owner not found")  // ログ用
                            return
                        }
                        
                        // 自分自身の投稿には通知しない
                        guard postOwnerID != uid else {
                            print("Comment notification skipped: own post")  // ログ用
                            return
                        }
                        
                        try await self.userRepository.createNotification(
                            recipientID: postOwnerID,
                            senderID: uid,
                            type: .comment,
                            postID: postId
                        )
                        
                        print("Comment notification created successfully")  // ログ用
                        
                    } catch {
                        print(
                            "Comment notification failed:",
                            error.localizedDescription
                        )
                    }
                }
            }
        
        // 投稿のコメント数を更新
        self.db.collection("posts")
            .document(postId)
            .updateData([
                "commentCount": FieldValue.increment(Int64(1))
            ]) { error in  // ログ用
                if let error = error {
                    print("Comment count update failed:", error.localizedDescription)
                } else {
                    print("Comment count update succeeded")
                }
            }  // ログ用ここまで
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
                        profileImageURL: data["profileImageURL"] as? String ?? "",
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
    
    func savePost(postId: String) async throws {
        
        guard let uid = Auth.auth().currentUser?.uid else {
           
            return
        }
  
        try await userRepository.savePost(
            uid: uid,
            postId: postId
        )
        
    }
    
    func unsavePost(postId: String) async throws {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        try await userRepository.unsavePost(
            uid: uid,
            postId: postId
        )
    }
    
    func fetchSavedPostIDs() async throws -> Set<String> {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return []
        }
        
        return try await userRepository.fetchSavedPostIDs(
            uid: uid
        )
    }
    
    func toggleSave(
        postId: String,
        isSaved: Bool
    ) async throws {
        
        if isSaved {
            
            try await unsavePost(
                postId: postId
            )
        } else {
            
            try await savePost(
                postId: postId
            )
        }
    }
    
}
