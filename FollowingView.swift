//
//  FollowingView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/08/19.
//

import SwiftUI
import FirebaseAuth

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
                    followState: followState(for: user),
                    onFollowTap: {
                        Task {
                            if viewModel.followingUserIDs.contains(user.id) {
                                await viewModel.unfollow(userID: user.id)
                            } else {
                                await viewModel.follow(userID: user.id)
                            }
                        }
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
    
    // MARK: - Follow State
    
    private func followState(for user: User) -> FollowButton.State? {
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return nil
        }
        
        guard user.id != currentUserID else {
            return nil
        }
        
        return viewModel.followingUserIDs.contains(user.id)
        ? .following
        : .follow
    }
}


/*
#Preview {
    FollowingView()
}
*/
