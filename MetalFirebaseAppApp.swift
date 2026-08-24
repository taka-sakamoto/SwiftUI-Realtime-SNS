//
//  MetalFirebaseAppApp.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/04/30.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct MetalFirebaseAppApp: App {
    
    @Namespace private var animation
    
    @StateObject private var imageListViewModel = ImageListViewModel()
    
    @StateObject private var profileViewModel = ProfileViewModel()
    
    @State private var currentUserID: String?

    init() {
        FirebaseApp.configure()
    }
    
    // MARK: - Authentication
    
    private func signInAnonymously() {
        
        Auth.auth().signInAnonymously { result, error in
            
            if let error = error {
                print("Auth error:", error.localizedDescription)
                return
            }
            
            guard let uid = result?.user.uid else {
                return
            }
            
            print("UserID:", uid)
            
            Task { @MainActor in
                currentUserID = uid
                await profileViewModel.loadOrCreateUser()
            }
        }
    }
    
    private func switchAnonymousUser() {
        
        profileViewModel.clearUserState()
        currentUserID = nil
        
        do {
            try Auth.auth().signOut()
            
            print("SIGN OUT SUCCESS")
            
            signInAnonymously()
            
        } catch {
            print("SIGN OUT FAILED:", error.localizedDescription)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            
            TabView {
                
                ContentView(
                    viewModel: imageListViewModel,
                    namespace: animation
                )
                .tabItem {
                    Label(
                        "Feed",
                        systemImage: "house"
                    )
                }
                
                CameraScreen()
                    .tabItem {
                        Label(
                            "Camera",
                            systemImage: "camera"
                        )
                    }
                
                NavigationStack {
                    
                    ProfileView(
                        viewModel: profileViewModel,
                        imageListViewModel: imageListViewModel,
                        namespace: animation,
                        userID: currentUserID,
                        onSwitchUser: {
                            switchAnonymousUser()
                        },
                        showsSwitchUser: true
                    )
                }
                .tabItem {
                    Label(
                        "Profile",
                        systemImage: "person"
                    )
                }
            }
            .task {
                signInAnonymously()
            }
        }
    }
}
