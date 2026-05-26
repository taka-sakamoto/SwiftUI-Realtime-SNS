//
//  FullScreenImageView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/05/05.
//

import Foundation
import UIKit
import SwiftUI

struct FullScreenImageView: View {
    let imageUrl: String
    let postId: String
    let namespace: Namespace.ID
    let onClose: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offsetY: CGFloat = 0
    
    var body: some View {
        
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            AsyncImage(url: URL(string: imageUrl)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        
                        .frame(
                            maxWidth: 350,
                            maxHeight: 600
                        )
                    
                        
                    
                    
                case .empty:
                    ProgressView()
                    
                case .failure:
                    Color.gray
                    
                @unknown default:
                    EmptyView()
                }
            }
            
            .matchedGeometryEffect(
                id: postId,
                in: namespace,
                isSource: false
            )
        
            .zIndex(1)
        }
        
        .onTapGesture {
            onClose()
        }
        
        .offset(y: offsetY)
        .gesture(
            DragGesture()
                .onChanged { value in
                    offsetY = value.translation.height
                }
                .onEnded { value in
                    if value.translation.height > 150 {

                        withAnimation(.spring(
                            response: 0.4,
                            dampingFraction: 0.85
                        )) {

                            onClose()
                        }

                    } else {

                        withAnimation {

                            offsetY = 0
                        }
                    }
                }
        )
    }
}

