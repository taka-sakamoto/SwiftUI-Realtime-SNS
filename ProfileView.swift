//
//  ProfileView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/05/20.
//

import SwiftUI

struct ProfileView: View {
    
    @AppStorage("userName")
    var userName = ""
    
    @StateObject private var viewModel =
    ProfileViewModel()
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    let namespace: Namespace.ID
    
    @State private var selectedImageItem:
    SelectedImage?
    
    @State private var showingEditProfile = false
    
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
                    
                    Text(viewModel.user?.displayName ?? userName)
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
                            
                            AsyncImage(
                                url: URL(string: post.imageUrl)
                                // transaction: Transaction(animation: .easeInOut)
                            ) { phase in
                                
                                switch phase {
                                    
                                case .success(let image):
                                    
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipped()
                                        
                                case .empty:
                                    
                                    ProgressView()
                                        .frame(width: 120, height: 120)
                                    
                                case .failure(let error):
                                    
                                    Color.gray
                                            .frame(width: 120, height: 120)
                                            .onAppear {
                                                #if DEBUG
                                                print("AsyncImage Error:", error)
                                                #endif
                                            }

                                    
                                @unknown default:
                                    
                                    EmptyView()
                                }
                            }
                            .id(post.id)
                        }
                    }
                }
                
                .padding()
            }
            .onAppear {
                viewModel.fetchMyPosts()
                
                Task {
                    
                    await viewModel.loadUser()
                }
                print("Profile appear") // デバッグ
            }
           
            if let item = selectedImageItem {
                
                FullScreenImageView(
                    imageUrl: item.url,
                    postId: item.id,
                    namespace: namespace,
                    onClose: {
                        
                        withAnimation(.spring(
                            response: 0.45,
                            dampingFraction: 0.82
                        )) {
                            selectedImageItem = nil
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
