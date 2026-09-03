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
    @ObservedObject var authViewModel: AuthViewModel
    
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var followListViewModel = FollowListViewModel()
    
    @State private var selectedDetailPost: Post? // 拡大表示用
    @State private var selectedCommentPost: Post?
    @State private var showUploadView = false
    @State private var selectedProfile: SelectedProfile?
    @State private var showUserSearch = false
    @State private var selectedFilter: FilterType = .invert
    
    @State private var showFollowingOnly = false
    
    private var displayPosts: [Post] {
        if showFollowingOnly {
            return viewModel.posts.filter {
                followListViewModel.followingUserIDs.contains($0.userId)
            }
        } else {
            return viewModel.posts
        }
    }
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    let namespace: Namespace.ID
    
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
    
    // MARK: - Sign Out
    
    private func signOut() -> Bool {
        
        profileViewModel.clearUserState()
        
        do {
            
            try Auth.auth().signOut()
            
            return true
            
        } catch {
            print("SIGN OUT FAILED:", error.localizedDescription)
            
            return false
        }
    }
    
    // MARK: - Switch Anonymous User
    
    private func switchAnonymousUser() {
        
        guard signOut() else {
            return
        }
        
        signInAnonymously()
    }
    
    var body: some View {
        ZStack {
            
            NavigationStack {
                
                VStack {
                    
                    Picker("表示", selection: $showFollowingOnly) {
                        Text("すべて")
                            .tag(false)
                        
                        Text("フォロー中")
                            .tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // 投稿ボタン
                    Button("投稿") {
                        showUploadView = true
                    }
                    .padding()
                    
                    // 画像一覧
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            
                            let displayedPosts = showFollowingOnly
                                ? viewModel.posts.filter {
                                    followListViewModel.followingUserIDs.contains($0.userId)
                                }
                                : viewModel.posts
            
                            ForEach(displayedPosts) { post in
                                
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
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showUserSearch = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                }
                .navigationDestination(item: $selectedProfile) { profile in
                        ProfileView(
                            viewModel: profileViewModel,
                            imageListViewModel: viewModel,
                            namespace: namespace,
                            userID: profile.id,
                            onLogout:  {
                                authViewModel.signOut()
                            }
                        )
                }
            }
            .onAppear {
                viewModel.startListening()
                
                Task {
                    await followListViewModel.fetchFollowingStatus()
                }
               
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
        .sheet(isPresented: $showUserSearch) {
            UserSearchView(
                profileViewModel: profileViewModel,
                imageListViewModel: viewModel,
                namespace: namespace,
                onLogout: {
                    authViewModel.signOut()
                }
            )
        }
        
    }
    
}

/*
#Preview {
    ContentView()
}
*/
