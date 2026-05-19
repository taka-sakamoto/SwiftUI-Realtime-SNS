//
//  CommentView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/05/18.
//

import SwiftUI
import FirebaseAuth

struct CommentView: View {
    
    let post: Post
    
    @State private var comments: [Comment] = []
    
    @State private var text = ""
    
    @AppStorage("userName")
    var userName = ""
    
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
                        
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(String(comment.userName.prefix(1)))
                                    .font(.caption)
                            )
                        
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
                        
                        print("comment userName:", userName)

                        guard let uid =
                        Auth.auth().currentUser?.uid
                        else { return }

                        FirebaseService.shared.addComment(
                            postId: post.id,
                            text: text,
                            uid: uid,
                            userName: userName
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
        
        
    }
}


/*
#Preview {
    CommentView()
}
*/
