//
//  ProfileView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/05/20.
//

import SwiftUI
import Kingfisher

struct ProfileView: View {
    
    // MARK: - Dependencies
    
    @StateObject private var viewModel =
    ProfileViewModel()
    
    @ObservedObject var imageListViewModel: ImageListViewModel
    
    let namespace: Namespace.ID
    
    // MARK: - State
    
    @State private var showingEditProfile = false
    
    @State private var selectedDetailPost: Post?
    
    @State private var selectedTab = 0
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
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
                    
                    Picker("", selection: $selectedTab) {
                        
                        Text("Posts")
                            .tag(0)
                        
                        Text("Saved")
                            .tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
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
                viewModel.fetchMyPosts()
               
                    Task {
                        
                        await viewModel.loadUser()
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
