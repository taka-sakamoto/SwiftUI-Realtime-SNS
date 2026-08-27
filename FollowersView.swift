//
//  FollowersView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/08/19.
//

import SwiftUI
import FirebaseAuth

struct FollowersView: View {
    
    // MARK: - Dependencies
    
    let userID: String
    
    // MARK: - State
    
    @StateObject private var viewModel = FollowListViewModel()
    
    // MARK: - Body
    
    var body: some View {
        List {
            ForEach(viewModel.users) { user in
                
                if userID != Auth.auth().currentUser?.uid ||
                    user.id != Auth.auth().currentUser?.uid {
                    
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
        }
        .navigationTitle("Followers")
        .task {
            await viewModel.fetchFollowers(userID: userID)
            await viewModel.fetchFollowingStatus()
        }
    }
    
    // MARK: -Follow State
    
    private func followState(for user: User) -> FollowButton.State? {
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return nil
        }
        
        guard user.id != currentUserID else {
            return nil
        }
        
        return viewModel.followingUserIDs.contains(user.id)
            ? .following
            : .followBack
    }
}


/*
#Preview {
    FollowersView()
}
*/
