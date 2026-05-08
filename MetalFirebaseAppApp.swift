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

    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
