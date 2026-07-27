//
//  CommentRow.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/07/26.
//

import SwiftUI
import Kingfisher
// import FirebaseAuth

struct CommentRow: View {
    
    // MARK: - Properties
    
    let comment: Comment
    let canDelete: Bool
    let onDelete: () -> Void
    
    // MARK: - Body
    
    var body: some View {
    
        HStack(alignment: .top, spacing: 12) {
            
            profileImage
            
            VStack(alignment: .leading, spacing: 4) {
                
                header
                
                content
            }
            
            Spacer()
        }
        // .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Components
    
    private var profileImage: some View {
        
        Group {

            if comment.profileImageURL.isEmpty {
                
                Circle()
                    .fill(Color.gray.opacity(0.3))
                
            } else {
                
                KFImage(URL(string: comment.profileImageURL))
                    .resizable()
                    .scaledToFill()
    
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
    }
    
    private var header: some View {
        
        HStack {
            
            Text(comment.userName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text(comment.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if canDelete {
                menuButton
            }
        }
    }
    
    private var content: some View {
        
        Text(comment.text)
            .font(.body)
            .foregroundStyle(.primary)
    }
    
    private var menuButton: some View {
        
        Menu {
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("削除", systemImage: "trash")
            }
            
        } label: {
            
            Image(systemName: "ellipsis.circle.fill")
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
        }
    }
    
    // MARK: - Computed Properties
    
    private var relativeDate: String {
        
        comment.createdAt.relativeString()
    }
}

/*
#Preview {
    CommentRow()
}
*/
