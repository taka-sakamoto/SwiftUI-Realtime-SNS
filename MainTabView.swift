//
//  MainTabView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/08/25.
//

import SwiftUI

struct MainTabView: View {
    
    // MARK: - Dependencies
    
    @ObservedObject var imageListViewModel: ImageListViewModel
    
    @ObservedObject var profileViewModel: ProfileViewModel
    
    @ObservedObject var authViewModel: AuthViewModel
    
    let namespace: Namespace.ID
    
    // MARK: - Body
    
    var body: some View {
        
        TabView {
            
            // MARK: - Feed
            
            ContentView(
                viewModel: imageListViewModel,
                authViewModel: authViewModel,
                namespace: namespace
            )
            .tabItem {
                Label(
                    "Feed",
                    systemImage: "house"
                )
            }
            
            // MARK: - Camera
            
            CameraScreen()
                .tabItem {
                    Label(
                        "Camera",
                        systemImage: "camera"
                    )
                }
            
            // MARK: - Profile
            
            NavigationStack {
                
                ProfileView(
                    viewModel: profileViewModel,
                    imageListViewModel: imageListViewModel,
                    namespace: namespace,
                    userID: authViewModel.userID,
                    onLogout: {
                        authViewModel.signOut()
                    }
                )
            }
            .tabItem {
                Label(
                    "Profile",
                    systemImage: "person"
                )
            }
        }
    }
}


/*
#Preview {
    MainTabView()
}
*/
