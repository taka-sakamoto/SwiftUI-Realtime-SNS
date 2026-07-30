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
import FirebaseAuth

struct PostDetailView: View {
    let post: Post
    let namespace: Namespace.ID
    let onClose: () -> Void
    
    @ObservedObject var viewModel: ImageListViewModel
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offsetY: CGFloat = 0
    
    @StateObject private var profileViewModel = ProfileViewModel()
    
    @State private var showBigHeart = false
    
    @State private var animateLike = false
    
    @State private var comments: [Comment] = []
    @State private var text = ""
    
    @State private var showDeleteAlert = false
    @State private var selectedComment: Comment?
    
    private var displayName: String {
        profileViewModel.user?.displayName ?? post.userName
    }
    
    private var profileImageURL: String? {
        profileViewModel.user?.profileImageURL
    }
    
    private var relativeDate: String {
        post.createdAt.relativeString()
    }
    
    private var isLiked: Bool {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return false
        }
        
        return post.likedBy.contains(uid)
    }
    
    var body: some View {
        
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            ScrollView {
                
                VStack(alignment: .leading, spacing: 16) {
                    
                    headerSection
                    
                    imageSection

                    actionBarSection
                    
                    captionSection
                    
                    Divider()
                    
                    commentsSection
                    
                    Divider()
                    
                    commentInputSection
                    
                    
                }
                .padding(.vertical)
                
            }
        }
        
        .onAppear {
            startListeningComments()
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
        
        .alert("コメントを削除しますか？",
               isPresented: $showDeleteAlert) {
            
            Button("削除", role: .destructive) {
                
                guard let comment = selectedComment else {
                    return
                }
                
                FirebaseService.shared.deleteComment(
                    postId: post.id,
                    commentId: comment.id
                )
                
            }
            
            Button("キャンセル", role: .cancel) { }
        }
    }
    
    private var headerSection: some View {
        
        HStack(spacing: 8) {
            
            ProfileImageView(
                imageURL: profileImageURL,
                selectedImage: nil,
                displayName: displayName
            )
            .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                
                Text(displayName)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text(relativeDate)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var imageSection: some View {
        
        ZStack {
            
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
                
                Spacer()
            }
            
            if showBigHeart {
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(radius: 10)
            }
            
        }
        .onTapGesture(count: 2) {
            
            viewModel.toggleLike(post: post)
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                showBigHeart = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation {
                    showBigHeart = false
                }
                
            }
        }
    }
    
    private var captionSection: some View {
        
        Group {
            
            if !post.caption.isEmpty {
                
                Text(post.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal)
            }
        }
    }
    
    private var actionBarSection: some View {
        
        HStack(spacing: 24) {
            
            likeGroup
            
            saveGroup
            
            commentGroup
            
            Spacer()
        }
        .padding(.horizontal)
        
    }
    
    private var commentsSection: some View {
        
        ForEach(comments) { comment in

            CommentRow(
                comment: comment,
                canDelete: comment.userId == profileViewModel.user?.id,
                onDelete: {
                    selectedComment = comment
                    showDeleteAlert = true
                }
            )
        }
        .foregroundStyle(.white)
    }
    
    // MARK: - Sections
    
    private var commentInputSection: some View {
        
        HStack {
            
            TextEditor(text: $text)
                .frame(minHeight: 40, maxHeight: 100)
                .padding(4)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Button("送信") {
                addComment()
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
    
    private func likePost() {
        
        // 後で既存Like処理を移植
    }
    
    private var likeGroup: some View {
        
        HStack(spacing: 4) {
            
            Button {
                
                viewModel.toggleLike(post: post)
                
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                animateLike = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    animateLike = false
                }
                
            } label: {
                
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundStyle(isLiked ? .red : .gray)
                    .scaleEffect(animateLike ? 1.5 : 1.0)
                    .animation(
                        .spring(response: 0.25, dampingFraction: 0.5),
                        value: animateLike
                    )
            }
            
            Text("\(post.likedBy.count)")
                .foregroundStyle(.white)
        }
    }
    
    private var commentGroup: some View {
        
        HStack(spacing: 4) {
            
            Button {
                
                // TODO: コメント欄へスクロール
                
            } label: {
                
                Image(systemName: "message")
                    .foregroundStyle(.white)
            }
            
            Text("\(post.commentCount)")
                .foregroundStyle(.white)
        }
    }
    
    // MARK: - Components
    
    private var saveGroup: some View {
        
        Button {
            
            Task {
                await viewModel.toggleSave(
                    post: post
                )
                
            }
            
        } label: {
            
            Image(
                systemName: viewModel.savedPostIDs.contains(post.id)
                ? "bookmark.fill"
                : "bookmark"
            )
            .font(.title3)
        }
    }
    
    // MARK: - Private Methods
    
    private func startListeningComments() {
        
        FirebaseService.shared.listenComments(
            postId: post.id
        ) { comments in
            
            self.comments = comments
        }
    }
    
    // MARK: - Private Methods
    
    private func addComment() {
        
        guard let user = profileViewModel.user else {
            return
        }
        
        FirebaseService.shared.addComment(
            postId: post.id,
            text: text,
            uid: user.id,
            userName: user.displayName,
            profileImageURL: user.profileImageURL
        )
        
        text = ""
    }
}

