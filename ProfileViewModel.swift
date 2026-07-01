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
    
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let repository = UserRepository()
    
    func loadUser() async {

        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        print("Current UID", uid)  // ログ用

        isLoading = true

        do {
            user = try await repository.fetchUser(uid: uid)
            print("Loaded User:", user)  // ログ用
        } catch {
            print("Load Error:", error)  // ログ用
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
