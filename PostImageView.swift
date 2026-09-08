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
    let useMatchedGeometry: Bool
    
    // MARK: - Body
    
    var body: some View {
    
        KFImage(URL(string: post.imageUrl))
            .placeholder {
                ProgressView()
            }
            .cancelOnDisappear(true)
            .resizable()
            .aspectRatio(contentMode: contentMode)
            .frame(
                width: size?.width,
                height: size?.height
            )
            .modifier(
                MatchedGeometryModifier(
                    postID: post.id,
                    namespace: namespace,
                    isSource: isSource,
                    enabled: useMatchedGeometry
                )
            )
            .clipped()
    }
    
    private struct MatchedGeometryModifier: ViewModifier {
        
        let postID: String
        let namespace: Namespace.ID
        let isSource: Bool
        let enabled: Bool
        
        func body(content: Content) -> some View {
            if enabled {
                content
                    .matchedGeometryEffect(
                        id: postID,
                        in: namespace,
                        isSource: isSource
                    )
            } else {
                content
            }
        }
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
        size: CGSize(width: 120, height: 120),
        useMatchedGeometry: true
    )
}
