//
//  ProfileView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/05/20.
//

import SwiftUI
import Kingfisher

struct ProfileView: View {
    
    @StateObject private var viewModel =
    ProfileViewModel()
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    let namespace: Namespace.ID
    
    @State private var showingEditProfile = false
    
    @State private var selectedDetailPost: Post?
    
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
                }
                
                .padding()
            }
            .onAppear {
                viewModel.fetchMyPosts()
                print("Profile appear") // デバッグ
                
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
                    }
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
