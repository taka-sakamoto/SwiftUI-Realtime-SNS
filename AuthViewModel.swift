//
//  AuthViewModel.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/04/30.
//

import Foundation
import FirebaseAuth
import Combine

class AuthViewModel: ObservableObject {
    
    @Published var userId: String?
    
    init() {
        signInAnonymously()
    }
    
    func signInAnonymously() {
        Auth.auth().signInAnonymously { result, error in
            if let error = error {
                print("Login error:", error)
                return
            }
            
            self.userId = result?.user.uid
            print("UserID:", self.userId ?? "")
        }
        
    }
    
}
