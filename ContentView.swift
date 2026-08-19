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

struct SelectedProfile: Identifiable, Hashable {
    let id: String
}

struct ContentView: View {
    @ObservedObject var viewModel: ImageListViewModel
    @StateObject private var profileViewModel = ProfileViewModel()
    
    @State private var selectedDetailPost: Post? // 拡大表示用
    @State private var selectedCommentPost: Post?
    @State private var showUploadView = false
    @State private var selectedProfile: SelectedProfile?
    
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
    
    var body: some View {
        ZStack {
            
            NavigationStack {
                
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
                                           selectedDetailPost = post
                                        }
                                    },
                                    onLike: {
                                        viewModel.toggleLike(post: post)
                                    },
                                    onComment: {
                                        selectedCommentPost = post
                                    },
                                    onProfileTap: {
                                        selectedProfile = SelectedProfile(id: post.userId)
                                    },
                                    namespace: namespace,
                                    isSource: selectedDetailPost == nil
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                    
                }
                .navigationTitle("Images")
                .navigationDestination(item: $selectedProfile) { profile in
                        ProfileView(
                            imageListViewModel: viewModel,
                            namespace: namespace,
                            userID: profile.id
                        )
                }
            }
            .onAppear {
                
                signInAnonymously()
                viewModel.startListening()
               
            }
            
            if let post = selectedDetailPost {
                
                PostDetailView(
                    post: post,
                    namespace: namespace,
                    onClose: {
                    selectedDetailPost = nil
                    },
                    viewModel: viewModel
                )
                .transition(.identity)
                .zIndex(1)
            }
            
        }
        .sheet(item: $selectedCommentPost) { post in
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
