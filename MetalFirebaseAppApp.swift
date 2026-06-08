//
//  MetalFirebaseAppApp.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/04/30.
//

import SwiftUI
import FirebaseCore

@main
struct MetalFirebaseAppApp: App {
    
    @Namespace private var animation

    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            
            TabView {
                
                ContentView(
                    namespace: animation
                )
                .tabItem {
                    Label("Feed",
                            systemImage: "house")
                    }
                
                CameraScreen()
                    .tabItem {
                        Label("Camera",
                        systemImage: "camera")
                    }
                
                ProfileView(namespace: animation)
                    .tabItem {
                        Label("Profile",
                              systemImage: "person")
                    }
            }
        }
    }
}
