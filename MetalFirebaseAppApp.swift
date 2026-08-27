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
    
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        FirebaseApp.configure()
    }
    
    // MARK: - Authentication
    
    var body: some Scene {
        WindowGroup {
            
            if authViewModel.userID == nil {
                
                LoginView(
                    authViewModel: authViewModel,
                    profileViewModel: profileViewModel
                )
                
            } else {
                
                MainTabView(
                    imageListViewModel: imageListViewModel,
                    profileViewModel: profileViewModel,
                    authViewModel: authViewModel,
                    namespace: animation
                )
            }
        }
    }
}
