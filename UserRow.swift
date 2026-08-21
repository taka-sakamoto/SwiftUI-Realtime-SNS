//
//  UserRow.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/08/19.
//

import SwiftUI
import Kingfisher

struct UserRow: View {
    
    // MARK: - Dependencies
    
    let user: User
    let isFollowing: Bool
    let onFollowTap: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            
            KFImage(URL(string: user.profileImageURL ?? ""))
                .resizable()
                .placeholder {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            
            Text(user.displayName)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Spacer()
            
            FollowButton(
                isFollowing: isFollowing,
                action: onFollowTap
            )
            .frame(width: 110)
        }
        .padding(.vertical, 6)
    }
}


/*
#Preview {
    UserRow()
}
*/
