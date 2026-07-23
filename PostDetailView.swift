//
//  FullScreenImageView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/05/05.
//

import Foundation
import UIKit
import SwiftUI
import Kingfisher

struct PostDetailView: View {
    let post: Post
    let namespace: Namespace.ID
    let onClose: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offsetY: CGFloat = 0
    
    @StateObject private var profileViewModel = ProfileViewModel()
    
    var body: some View {
        
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            ScrollView {
                
                VStack(alignment: .leading, spacing: 16) {
                    
                    // Header
                    HStack(spacing: 8) {
                        
                        ProfileImageView(
                            imageURL: profileViewModel.user?.profileImageURL,
                            selectedImage: nil,
                            displayName: profileViewModel.user?.displayName ?? post.userName
                        )
                        .frame(width: 36, height: 36)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            
                            Text(profileViewModel.user?.displayName ?? post.userName)
                                .font(.headline)
                                .foregroundStyle(.white)
                            
                            Text(post.createdAt.relativeString())
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // image
                    HStack {
                        
                        Spacer()
                        
                        KFImage(URL(string: post.imageUrl))
                            .resizable()
                            .scaledToFit()
                            .frame(
                                maxWidth: 350,
                                maxHeight: 600
                            )
                        
                            .matchedGeometryEffect(
                                id: post.id,
                                in: namespace,
                                isSource: false
                            )
                        // .zIndex(1)
                        
                        Spacer()
                        
                    }
                    
                    if !post.caption.isEmpty {
                        
                        VStack(alignment: .leading, spacing: 4) {
                            
                            Text(profileViewModel.user?.displayName ?? post.userName)
                                .font(.headline)
                            
                            Text(post.caption)
                                .foregroundStyle(.white)
                            
                            
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                
            }
        }
        .task {
            await profileViewModel.fetchUser(uid: post.userId)
        }
        
        .onTapGesture {
            onClose()
        }
        
        .offset(y: offsetY)
        .gesture(
            DragGesture()
                .onChanged { value in
                    offsetY = value.translation.height
                }
                .onEnded { value in
                    if value.translation.height > 150 {

                        withAnimation(.spring(
                            response: 0.4,
                            dampingFraction: 0.85
                        )) {

                            onClose()
                        }

                    } else {

                        withAnimation {

                            offsetY = 0
                        }
                    }
                }
        )
    }
}

