//
//  SavedPostsView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/07/30.
//

import SwiftUI
import Kingfisher

struct SavedPostsView: View {
    
    // MARK: - Dependencies
    
    let namespace: Namespace.ID
    
    @ObservedObject var viewModel: ImageListViewModel
    
    @Binding var selectedDetailPost: Post?
    
    // MARK: - State
    
    // @State private var selectedPost: Post?
    
    // MARK: - Grid
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var isSource: Bool
    
    // MARK: - Body
    
    var body: some View {
        
        let gridSize = UIScreen.main.bounds.width / 3 - 4
            
        // gridSection
        LazyVGrid(columns: columns, spacing: 2) {
                
            ForEach(viewModel.savedPosts) { post in
                    
                PostImageView(
                    post: post,
                    namespace: namespace,
                    isSource: isSource,
                    contentMode: .fill,
                    size: CGSize(
                        width: gridSize,
                        height: gridSize
                    )
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(
                        response: 0.45,
                        dampingFraction: 0.82
                )) {
                    selectedDetailPost = post
                    }
                }

            }
        }

        .onAppear {  // ログ用
            
            print("SAVED POSTS VIEW:",
                  viewModel.savedPosts.map { $0.id })
        }  // ここまでログ用
        
        
        .navigationTitle("Saved")
        .navigationBarTitleDisplayMode(.inline)
       
    }
    
}


#Preview {
    
    @Previewable @Namespace var namespace
    @Previewable @State var selectedDetailPost: Post?
    
    NavigationStack {
        SavedPostsView(
            namespace: namespace,
            viewModel: ImageListViewModel(),
            selectedDetailPost: $selectedDetailPost,
            isSource: selectedDetailPost == nil
        )
    }
    
}

