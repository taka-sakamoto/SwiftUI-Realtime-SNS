//
//  CommentView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/05/18.
//

import SwiftUI
import FirebaseAuth
import Kingfisher

struct CommentView: View {
    
    let post: Post
    
    @StateObject private var profileViewModel = ProfileViewModel()
    
    @State private var comments: [Comment] = []
    
    @State private var text = ""
    
    @State private var selectedComment: Comment?
    @State private var showDeleteAlert = false
    
    func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var body: some View {

        NavigationView {

            VStack {

                List(comments) { comment in
                    
                    HStack(alignment: .top, spacing: 12) {
                        
                        if comment.profileImageURL.isEmpty {
                            
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .foregroundStyle(.gray)
                            
                        } else {
                            
                            KFImage(URL(string: comment.profileImageURL))
                                .placeholder {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFill()
                                        .foregroundStyle(.gray)
                                }
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                                
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            
                            HStack {
                                
                                Text(comment.userName)
                                    .font(.headline)
                                
                                Text(relativeDate(comment.createdAt))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                if comment.userId ==
                                    Auth.auth().currentUser?.uid {
                                    
                                    Button(role: .destructive) {
                                        
                                        selectedComment = comment
                                        showDeleteAlert = true
                                        
                                    } label: {
                                        
                                        Image(systemName: "trash")
                                            .font(.caption)
                                    }
                                }
                            }
                            
                            Text(comment.text)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }

                HStack {

                    TextEditor(text: $text)
                        .frame(minHeight: 40, maxHeight: 100)
                        .padding(4)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Button("送信") {
                        
                        //print("comment userName:", userName)

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
                .padding()
            }
            .navigationTitle("Comments")
        }
        
        .onAppear {

            FirebaseService.shared.listenComments(
                postId: post.id
            ) { comments in

                self.comments = comments
            }
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

            Button("キャンセル", role: .cancel) {}
        }
        
        .task {
            await profileViewModel.loadOrCreateUser()
        }
        
        
    }
}


/*
#Preview {
    CommentView()
}
*/
