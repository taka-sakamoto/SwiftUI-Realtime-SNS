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
    
    var body: some View {
        
        ZStack {
            ScrollView {
                
                VStack(spacing: 16) {
                    
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(String(userName.prefix(1)))
                                .font(.largeTitle)
                        )
                    
                    Text(userName)
                        .font(.title2)
                    
                    LazyVGrid(columns: columns, spacing: 2) {
                        
                        ForEach(viewModel.posts) { post in
                            
                            AsyncImage(url: URL(string: post.imageUrl)) { phase in
                                
                                switch phase {
                                    
                                case .success(let image):
                                    
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .contentShape(Rectangle())
                                        .clipped()
                                        
                                        .onTapGesture {
                                            
                                            withAnimation(.spring(
                                                response: 0.45,
                                                dampingFraction: 0.82
                                            )) {
                                                
                                                selectedImageItem =
                                                SelectedImage(
                                                    id: post.id,
                                                    url: post.imageUrl
                                                )
                                            }
                                        }
                                    
                                case .empty:
                                    
                                    ProgressView()
                                        .frame(width: 120, height: 120)
                                    
                                case .failure:
                                    
                                    Color.gray
                                        .frame(width: 120, height: 120)
                                    
                                @unknown default:
                                    
                                    EmptyView()
                                }
                            }
                            .matchedGeometryEffect(
                                id: post.id,
                                in: namespace,
                                isSource: selectedImageItem == nil
                            )
                        }
                    }
                }
                
                .padding()
            }
            .onAppear {
                viewModel.fetchMyPosts()
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
                // .transition(.scale)
                .zIndex(1)
            }
        }
    }

}


/*
#Preview {
    ProfileView()
}
*/
