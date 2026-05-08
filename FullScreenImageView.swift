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
    @Environment(\.dismiss) var dismiss
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offsetY: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.black
                .opacity(max(0.2, 1 - abs(offsetY) / 300.0))
                .ignoresSafeArea()
            
            AsyncImage(url: URL(string: imageUrl)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = lastScale * value
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                }
                        )

                case .empty:
                    ProgressView()
                    
                case .failure:
                    Color.gray
                    
                @unknown default:
                    EmptyView()
                }
            }
        }
        .onTapGesture(count: 2) {
            if scale > 1 {
                scale = 1
                lastScale = 1
            } else {
                scale = 2
                lastScale = 2
            }
        }
        .offset(y: offsetY)
        .gesture(
            DragGesture()
                .onChanged { value in
                    offsetY = value.translation.height
                }
                .onEnded { value in
                    if value.translation.height > 150 {
                        dismiss()
                    } else {
                        withAnimation {
                            offsetY = 0
                        }
                    }
                }
        )
    }
}
