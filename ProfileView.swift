//
//  ProfileView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/05/20.
//

import SwiftUI
import Kingfisher
import FirebaseAuth

struct ProfileView: View {
    
    // MARK: - Dependencies
    
    @StateObject private var viewModel =
    ProfileViewModel()
    
    @ObservedObject var imageListViewModel: ImageListViewModel
    
    let namespace: Namespace.ID
    
    let userID: String?
    
    // MARK: - State
    
    @State private var showingEditProfile = false
    
    @State private var selectedDetailPost: Post?
    
    @State private var selectedTab = 0
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private var isMyProfile: Bool {
        guard let userID else {
            return true
        }
        
        return userID == Auth.auth().currentUser?.uid
    }
    
    var body: some View {
        
        ZStack {
            ScrollView {
                
                VStack(spacing: 16) {
                    
                    ProfileImageView(
                        imageURL: viewModel.user?.profileImageURL,
                        selectedImage: nil,
                        displayName: viewModel.user?.displayName
                    )
                    .frame(width: 100, height: 100)
                    
                    Text(viewModel.user?.displayName ?? "")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let bio = viewModel.user?.bio,
                       !bio.isEmpty {
                        
                        Text(bio)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    if isMyProfile {
                        
                        Button {
                            showingEditProfile = true
                        } label: {
                            Text("Edit Profile")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(.horizontal)
                        
                    } else {
                        
                        Button {
                            print("FOLLOW BUTTON TAPPED")  // ログ用
                            print("TARGET USER ID:", userID ?? "nil")  // ログ用
                            
                            guard let userID else { return }
                            
                            Task {
                                if viewModel.isFollowing {
                                    await viewModel.unfollow(targetUserID: userID)
                                } else {
                                    await viewModel.follow(targetUserID: userID)
                                }
                            }
                        } label: {
                            Text(viewModel.isFollowing ? "Following" : "Follow")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(.horizontal)
                    }
                    
                    if isMyProfile {
                        Picker("", selection: $selectedTab) {
                            
                            Text("Posts")
                                .tag(0)
                            
                            Text("Saved")
                                .tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                    } else {
                        
                        Text("Post")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    
                    if selectedTab == 0 {
                        
                        LazyVGrid(columns: columns, spacing: 2) {
                            
                            ForEach(viewModel.posts, id: \.id) { post in
                                
                                KFImage(URL(string: post.imageUrl))
                                    .resizable()
                                    .placeholder {
                                        ProgressView()
                                            .frame(width: 120, height: 120)
                                    }
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipped()
                                    .id(post.id)
                            }
                        }
                    } else {
                        
                        SavedPostsView(
                            namespace: namespace,
                            viewModel: imageListViewModel,
                            selectedDetailPost: $selectedDetailPost,
                            isSource: selectedDetailPost == nil
                            
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
                
                .padding()
            }
            .onAppear {
                let targetUserID =
                userID ?? Auth.auth().currentUser?.uid
                
                guard let targetUserID else {
                    return
                }
                
                Task {
                    await viewModel.loadProfile(userID: targetUserID)
                    
                    if !isMyProfile {
                        await viewModel.checkFollowing(
                            targetUserID: targetUserID
                        )
                    }
                }
            }
           
            if let post = selectedDetailPost {
                
                PostDetailView(
                    post: post,
                    namespace: namespace,
                    onClose: {
                        
                        withAnimation(.spring(
                            response: 0.45,
                            dampingFraction: 0.82
                        )) {
                            selectedDetailPost = nil
                        }
                    },
                    viewModel: imageListViewModel
                )
                
                .zIndex(1)
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(viewModel: viewModel)
        }
    }

}


/*
#Preview {
    ProfileView()
}
*/
