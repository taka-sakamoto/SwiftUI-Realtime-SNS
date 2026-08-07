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
    
    // MARK: - Properties
    
    let post: Post
    let namespace: Namespace.ID
    let onClose: () -> Void
    
    @ObservedObject var viewModel: ImageListViewModel
    
    @StateObject private var profileViewModel = ProfileViewModel()
    
    @State private var showBigHeart = false
    
    @State private var animateLike = false
    
    @State private var comments: [Comment] = []
    @State private var text = ""
    
    @State private var showDeleteAlert = false
    @State private var selectedComment: Comment?
    
    // MARK: - Computed Properties
    
    private var displayName: String {
        profileViewModel.user?.displayName ?? post.userName
    }
    
    private var profileImageURL: String? {
        profileViewModel.user?.profileImageURL
    }
    
    private var relativeDate: String {
        post.createdAt.relativeString()
    }
    
    private var currentPost: Post {
        
        let found = viewModel.posts.first { $0.id == post.id } // ログ用
        
        print("DETAIL POST:", post.id)
        print("FOUND:", found?.id ?? "nil")
        print("POST COUNT:", viewModel.posts.count)
        
        return found ?? post  // ログ用ここまで
        
    }
    
    private var isLiked: Bool {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return false
        }
        
        return currentPost.likedBy.contains(uid)
    }
    
    // MARK: - Body
    
    var body: some View {
        
        ZStack {
            Color.black
                .ignoresSafeArea()
           
            ScrollView {
                
                VStack(spacing: 16) {
                    
                    headerSection
                    
                    imageSection
                    
                    actionBarSection
                    
                    captionSection
                    
                    Divider()
                    
                    commentsSection
                    
                    Divider()
                    
                    commentInputSection
                    
                    
                }
                .frame(maxWidth: .infinity)
                // .padding(.vertical)
                
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
    
    // MARK: - SEctions
    
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

       PostImageView(
        post: post,
        namespace: namespace,
        isSource: false,
        contentMode: .fit,
        size: CGSize(
            width: UIScreen.main.bounds.width,
            height: UIScreen.main.bounds.width
        )
       )
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
    
    private var captionSection: some View {
        
        Group {
            
            if !post.caption.isEmpty {
                
                Text(post.caption)
                    .foregroundStyle(.white)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(.horizontal)
            }
        }
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
    
    // MARK: - Components
    
    private var likeGroup: some View {
        
        HStack(spacing: 4) {
            
            Button {
                
                viewModel.toggleLike(post: currentPost)
                
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
            
            Text("\(currentPost.likedBy.count)")
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
    
    private var saveGroup: some View {
        
        Button {
            
            Task {
                await viewModel.toggleSave(
                    post: currentPost
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

