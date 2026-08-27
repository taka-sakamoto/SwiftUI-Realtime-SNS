//
//  FollowListViewModel.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/08/19.
//

import Foundation
import FirebaseAuth
import Combine

@MainActor
final class FollowListViewModel: ObservableObject {
    
    // MARK: - Dependencies
    
    private let repository = UserRepository()
    
    // MARK: - State
    
    @Published var users: [User] = []
    @Published var followingUserIDs: Set<String> = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Fetch Followers
    
    func fetchFollowers(userID: String) async {
        
        isLoading = true
        
        do {
            let userIDs = try await  repository.fetchFollowerUserIDs(
                userID: userID
            )

            let fetchedUsers = try await withThrowingTaskGroup(
                of: User?.self
            ) { group in
                
                for userID in userIDs {
                    group.addTask {
                        try await self.repository.fetchUser(uid: userID)
                    }
                }
                
                var users: [User] = []
                
                for try await user in group {
                    if let user {
                        users.append(user)
                    }
                }
                
                return users
            }
            
            users = fetchedUsers
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Fetch Following
    
    func fetchFollowing(userID: String) async {
        
        isLoading = true
        
        do {
            let userIDs = try await repository.fetchFollowingUserIDs(
                userID: userID
            )
            
            let fetchedUsers = try await withThrowingTaskGroup(
                of: User?.self
            ) { group in
                
                for userID in userIDs {
                    group.addTask {
                        try await self.repository.fetchUser(uid: userID)
                    }
                }
                
                var users: [User] = []
                
                for try await user in group {
                    if let user {
                        users.append(user)
                    }
                }
                
                return users
            }
            
            users = fetchedUsers
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Fetch Following Status
    
    func fetchFollowingStatus() async {
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        do {
            let userIDs = try await repository.fetchFollowingUserIDs(
                userID: currentUserID
            )
            
            followingUserIDs = Set(userIDs)
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Follow
    
    func follow(userID: String) async {
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        guard currentUserID != userID else {
            return
        }
        
        do {
            try await repository.followUser(
                currentUserID: currentUserID,
                targetUserID: userID
            )
            
            followingUserIDs.insert(userID)
            
        } catch {
            
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Unfollow
    
    func unfollow(userID: String) async {
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        guard currentUserID != userID else {
            return
        }
        
        do {
            try await repository.unfollowUser(
                currentUserID: currentUserID,
                targetUserID: userID
            )
            
            followingUserIDs.remove(userID)
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
