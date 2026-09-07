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
    @Binding var detailSource: ProfileView.DetailSource?
    
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
                    ),
                    useMatchedGeometry: true
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(
                        response: 0.45,
                        dampingFraction: 0.82
                )) {
                    detailSource = .saved
                    selectedDetailPost = post
                    }
                }

            }
        }

        .onAppear {  // ログ用
            
            print("SAVED POSTS VIEW:",viewModel.savedPosts.map { $0.id })
            print("SAVED isSource:", isSource)
            print("SAVED selectedDetailPost:", selectedDetailPost?.id as Any)
        }  // ここまでログ用
        
        
        .navigationTitle("Saved")
        .navigationBarTitleDisplayMode(.inline)
       
    }
    
}


#Preview {
    
    @Previewable @Namespace var savedNamespace
    @Previewable @State var selectedDetailPost: Post?
    @Previewable @State var detailSource: ProfileView.DetailSource?
    
    NavigationStack {
        SavedPostsView(
            namespace: savedNamespace,
            viewModel: ImageListViewModel(),
            selectedDetailPost: $selectedDetailPost,
            detailSource: $detailSource,
            isSource: selectedDetailPost == nil
        )
    }
    
}

