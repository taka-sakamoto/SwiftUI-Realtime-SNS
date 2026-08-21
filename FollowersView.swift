//
//  FollowersView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/08/19.
//

import SwiftUI

struct FollowersView: View {
    
    // MARK: - Dependencies
    
    let userID: String
    
    // MARK: - State
    
    @StateObject private var viewModel = FollowListViewModel()
    
    // MARK: - Body
    
    var body: some View {
        List {
            ForEach(viewModel.users) { user in
                
                UserRow(
                    user: user,
                    isFollowing: viewModel.followingUserIDs.contains(user.id),
                    onFollowTap: {
                        // 次に実装
                    }
                )
            }
        }
        .navigationTitle("Followers")
        .task {
            await viewModel.fetchFollowers(userID: userID)
            await viewModel.fetchFollowingStatus()
        }
    }
}


/*
#Preview {
    FollowersView()
}
*/
