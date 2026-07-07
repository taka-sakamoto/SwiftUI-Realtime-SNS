//
//  PostRow.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/05/03.
//

import SwiftUI
import FirebaseAuth

struct PostRow: View {
    let post: Post
    let user: User?
    
    let onDelete: () -> Void
    let onTap: () -> Void
    let onLike: () -> Void
    let onComment: () -> Void
    
    let namespace: Namespace.ID
    let isSource: Bool
    
    @State private var showAlert = false
    
    @State private var animateLike = false
    @State private var showBigHeart = false
    
    func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var body: some View {
        
        let isLiked = post.likedBy.contains(Auth.auth().currentUser?.uid ?? "")

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ProfileImageView(
                    imageURL: user?.profileImageURL,
                    selectedImage: nil,
                    displayName: user?.displayName ?? post.userName
                )
                .frame(width: 36, height: 36)
                
                VStack(alignment: .leading, spacing: 2) {
                    
                    Text(user?.displayName ?? post.userName)
                        .font(.headline)
                    
                    Text(relativeDate(post.createdAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
            }
            
            ZStack {
                AsyncImage(url: URL(string: post.imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit() // 元比率維持
  
                    case .empty:
                        ProgressView()
                        
                    case .failure:
                        Color.gray
                        
                    @unknown default:
                        EmptyView()
                    }
                }
                
                // 中央ハート❤️
                if showBigHeart {
                    Image(systemName: "heart.fill")
                        .font(.system(size:80))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(radius: 10)
                }
            }
            
            HStack {
                Button {
                    onLike()
                    
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    
                    animateLike = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        animateLike = false
                    }
                    
                } label: {
                    // いいね処理
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .gray)
                        .scaleEffect(animateLike ? 1.5 : 1.0)
                        .animation(
                            .spring(response: 0.25, dampingFraction: 0.5),
                            value: animateLike
                        )
                        
                }

                Text("\(post.likedBy.count)")
                    .font(.caption)
                
                HStack(spacing: 4) {
                    
                    Button {
                        onComment()
                    } label: {
                        Image(systemName: "message")
                    }
                    
                    Text("\(post.commentCount)")
                        .font(.caption)
                }
                
                Spacer()
                
                if post.userId == Auth.auth().currentUser?.uid {
                    Button("削除", role: .destructive) {
                        showAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            
        }
        .padding(.horizontal)
        
        .alert("削除しますか？", isPresented: $showAlert) {
            Button("削除", role:  .destructive) {
                onDelete()
            }
            Button("キャンセル", role: .cancel) {}
        }
        
        .onTapGesture(count: 2) {
            
            onLike()
            
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
        
        .onTapGesture {
            onTap()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        
    }
}


/*
#Preview {
    PostRow()
}
*/
