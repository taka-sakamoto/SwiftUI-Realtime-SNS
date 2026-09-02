//
//  UserSearchView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/08/28.
//

import SwiftUI

struct UserSearchView: View {
    
    // MARK: - Dependencies
    
    @ObservedObject var profileViewModel: ProfileViewModel
    @ObservedObject var imageListViewModel: ImageListViewModel
    
    let namespace: Namespace.ID
    let onLogout: () -> Void
    
    // MARK: - State
    
    @StateObject private var viewModel = UserSearchViewModel()
    @State private var selectedUserID: String?
    
    // MARK: - Body
    
    var body: some View {
        
        NavigationStack {
            
            List(viewModel.users) { user in
                
                UserRow(
                    user: user,
                    followState: nil,
                    onFollowTap: {}
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedUserID = user.id
                }
            }
            .navigationTitle("Search")
            .searchable(
                text: $viewModel.searchText,
                prompt: "Search users"
            )
            .task(id: viewModel.searchText) {
                try? await Task.sleep(for: .milliseconds(300))
                await viewModel.searchUsers()
            }
            .navigationDestination(item: $selectedUserID) { userID in
                ProfileView(
                    viewModel: profileViewModel,
                    imageListViewModel: imageListViewModel,
                    namespace: namespace,
                    userID: userID,
                    onLogout: onLogout
                )

            }
        }
    }
}


/*
#Preview {
    UserSearchView()
}
*/
