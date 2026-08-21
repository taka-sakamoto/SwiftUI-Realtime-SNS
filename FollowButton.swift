//
//  FollowButton.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/08/19.
//

import SwiftUI

struct FollowButton: View {
    
    // MARK: - Dependencies
    
    let isFollowing: Bool
    let action: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(isFollowing ? "Following" : "Follow")
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}


/*
 #Preview {
 FollowButton()
 }
*/
