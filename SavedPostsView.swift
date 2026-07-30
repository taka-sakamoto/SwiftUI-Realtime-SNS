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
    
    @ObservedObject var viewModel: ImageListViewModel
    
    // MARK: - Grid
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    // MARK: - Body
    
    var body: some View {
        
        ScrollView {
            
            // gridSection
            LazyVGrid(columns: columns, spacing: 2) {
                
                ForEach(viewModel.savedPosts) { post in
                    
                    KFImage(URL(string: post.imageUrl))
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                    
                }
            }
            
        }
        .navigationTitle("Saved")
        .navigationBarTitleDisplayMode(.inline)
    }
    
}


#Preview {
    NavigationStack {
        SavedPostsView(
            viewModel: ImageListViewModel()
        )
    }
    
}

