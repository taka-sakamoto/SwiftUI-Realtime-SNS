//
//  ProfileImageView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/07/02.
//

import SwiftUI
import Kingfisher

struct ProfileImageView: View {
    
    let imageURL: String?
    let selectedImage: UIImage?
    let displayName: String?
    
    var body: some View {
        
        Group {
            
            if let selectedImage {
                
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                
            } else if
                let imageURL,
                !imageURL.isEmpty,
                let url = URL(string: imageURL) {
                    
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    
                    
            } else {
                
                placeholderView
            }
        }
        .clipShape(Circle())
    }
}

private extension ProfileImageView {
    
    @ViewBuilder
    private var placeholderView: some View {
        
        Circle()
            .fill(Color.gray.opacity(0.2))
            .overlay {
                
                Text(initial)
                    .font(.largeTitle)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }
    }
    
    private var initial: String {
        
        guard let displayName,
              !displayName.isEmpty else {
            
            return "U"
        }
        
        return String(displayName.prefix(1))
    }
}

#Preview {

    ProfileImageView(
        imageURL: nil,
        selectedImage: nil,
        displayName: "Takayuki"
    )
    .frame(width: 100, height: 100)
}


/*
#Preview {
    ProfileImageView()
}
*/
