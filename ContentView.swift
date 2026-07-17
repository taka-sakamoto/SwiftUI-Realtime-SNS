//
//  ContentView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/04/30.
//

import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore

struct SelectedImage: Identifiable {
    let id: String
    let url: String
}

struct ContentView: View {
    @StateObject var viewModel = ImageListViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    
    @State private var selectedImageItem: SelectedImage? // 拡大表示用
    @State private var selectedPost: Post?
    @State private var showUploadView = false
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    let namespace: Namespace.ID
    
    @State private var selectedFilter: FilterType = .invert
    
    func signInAnonymously() {
        Auth.auth().signInAnonymously { result, error in
            if let error = error {
                print("Auth error:", error.localizedDescription)
                return
            }
            
            Task {
                await profileViewModel.loadOrCreateUser()
            }
        }
    }
    
    /*
    func createUserIfNeeded(uid: String) {
        let ref = Firestore.firestore().collection("users").document(uid)
        
        ref.getDocument { snapshot, _ in
            if snapshot?.exists == true {
                return // すでに存在
            }
            
            let randomName = "User\(Int.random(in: 1000...9999))"
            
            ref.setData([
                "name": randomName,
                "createdAt": FieldValue.serverTimestamp()
            ])
            
            print("ユーザー作成:", randomName)
        }
    }
     */
    
    var body: some View {
        ZStack {
            
            NavigationView {
                
                VStack {
                    
                    // 投稿ボタン
                    Button("投稿") {
                        showUploadView = true
                    }
                    .padding()
                    
                    // 画像一覧
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
            
                            ForEach(viewModel.posts) { post in
                                
                                PostRow(
                                    post: post,
                                    user: viewModel.users[post.userId],
                                    onDelete: {
                                        viewModel.deletePost(post: post)
                                    },
                                    onTap: {
                                        withAnimation(.spring(response: 0.4,
                                                              dampingFraction: 0.85)) {
                                            selectedImageItem =
                                            SelectedImage(
                                                id: post.id,
                                                url: post.imageUrl
                                            )
                                        }
                                    },
                                    onLike: {
                                        viewModel.toggleLike(post: post)
                                    },
                                    onComment: {
                                        selectedPost = post
                                    },
                                    namespace: namespace,
                                    isSource: selectedImageItem == nil
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                    
                }
                .navigationTitle("Images")
            }
            .onAppear {
                
                signInAnonymously()
                viewModel.startListening()
               
            }
            
            if let item = selectedImageItem {
                
                FullScreenImageView(
                    imageUrl: item.url,
                    postId: item.id,
                    namespace: namespace,
                    onClose: {
                    selectedImageItem = nil
                    }
                )
                .zIndex(1)
            }
            
        }
        .sheet(item: $selectedPost) { post in
            CommentView(post: post)
        }
        
        .sheet(isPresented: $showUploadView) {
            
            PostUploadView(
                userName: profileViewModel.user?.displayName ?? ""
            )
            
        }
        
    }
    
}

/*
#Preview {
    ContentView()
}
*/
