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
    let id = UUID()
    let url: String
}

struct ContentView: View {
    @StateObject var viewModel = ImageListViewModel()
    @State private var selectedImageItem: SelectedImage? // 拡大表示用
    
    @State private var showPicker = false
    @State private var pickedImage: UIImage?   // 投稿用
    
    @State private var selectedPost: Post?
    
    @AppStorage("userName")
    var userName = ""
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    func signInAnonymously() {
        Auth.auth().signInAnonymously { result, error in
            if let error = error {
                print("Auth error:", error.localizedDescription)
                return
            }
            
            if let uid = Auth.auth().currentUser?.uid {
                createUserIfNeeded(uid: uid)
            }
        }
    }
    
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
    
    var body: some View {
        NavigationView {
            VStack {
                
                // 投稿ボタン
                Button("投稿") {
                    showPicker = true
                }
                .padding()
                
                // 画像一覧
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.posts) { post in
                            PostRow(
                                post: post,
                                onDelete: {
                                    viewModel.deletePost(post: post)
                                },
                                onTap: {
                                    selectedImageItem = SelectedImage(url: post.imageUrl)
                                },
                                onLike: {
                                    viewModel.toggleLike(post: post)
                                },
                                onComment: {
                                    selectedPost = post
                                }
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
            
            if userName.isEmpty {
                userName = "User\(Int.random(in: 1000...9999))"
            }
            signInAnonymously()
            viewModel.startListening()
        }
        .fullScreenCover(item: $selectedImageItem) { item in
            FullScreenImageView(imageUrl: item.url)
        }
        
        .sheet(item: $selectedPost) { post in
            CommentView(post: post)
        }
        
        .sheet(isPresented: $showPicker) {
            ImagePicker(image: $pickedImage)
        }
        .onChange(of: pickedImage) {
            guard let image = pickedImage else { return }
            
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            if let data = image.jpegData(compressionQuality: 0.8) {
                viewModel.uploadImage(data: data, uid: uid, name: userName)
                print("投稿userName:", userName)
            }
            
        }
        
        
    }
    
}

/*
#Preview {
    ContentView()
}
*/
