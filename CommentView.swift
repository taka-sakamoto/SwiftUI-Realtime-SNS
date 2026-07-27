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
    
    var body: some View {

        NavigationView {

            VStack {

                List(comments) { comment in
                    
                    CommentRow(
                        comment: comment,
                        canDelete: comment.userId == profileViewModel.user?.id,
                        onDelete: {
                            selectedComment = comment
                            showDeleteAlert = true
                        }
                    )
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
