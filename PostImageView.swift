//
//  PostImageView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/08/07.
//

import SwiftUI
import Kingfisher

struct PostImageView: View {
    
    // MARK: - Properties
    
    let post: Post
    let namespace: Namespace.ID
    
    let isSource: Bool
    let contentMode: SwiftUI.ContentMode
    let size: CGSize?
    
    // MARK: - Body
    
    var body: some View {
        
        KFImage(URL(string: post.imageUrl))
            .placeholder {
                ProgressView()
            }
            .cancelOnDisappear(true)
            .resizable()
            .aspectRatio(contentMode: contentMode)
            .matchedGeometryEffect(
                id: post.id,
                in: namespace,
                isSource: isSource
            )
            .frame(
                width: size?.width,
                height: size?.height
            )
            .clipped()
    }
}

#Preview {

    @Previewable @Namespace var namespace

    let post = Post(
        id: "preview",
        imageUrl: "",
        userId: "",
        userName: "Preview",
        imagePath: "",
        caption: "Preview Caption",
        filterName: "Normal",
        createdAt: Date(),
        likedBy: [],
        commentCount: 0
    )

    PostImageView(
        post: post,
        namespace: namespace,
        isSource: true,
        contentMode: .fill,
        size: CGSize(width: 120, height: 120)
    )
}
