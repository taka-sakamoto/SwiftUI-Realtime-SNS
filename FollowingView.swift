//
//  FollowingView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/08/19.
//

import SwiftUI

struct FollowingView: View {
    
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
        .navigationTitle("Following")
        .task {
            await viewModel.fetchFollowing(userID: userID)
            await viewModel.fetchFollowingStatus()
        }
    }
}


/*
#Preview {
    FollowingView()
}
*/
