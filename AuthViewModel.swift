//
//  AuthViewModel.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/04/30.
//

import Foundation
import FirebaseAuth
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    
    // MARK: - State
    
    @Published var userID: String?
    
    // MARK: - Dependencies
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    // MARK: - Initialzation
    
    init() {
        
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            
            self?.userID = user?.uid
            
        }
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async -> Bool {
        
        do {
            
            let result = try await Auth.auth()
                .signIn(
                    withEmail: email,
                    password: password
                )
            
            userID = result.user.uid
            
            return true
            
        } catch {
            
            print("SIGN IN ERROR:", error.localizedDescription)
            
            return false
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        
        do {
            
            try Auth.auth().signOut()
            
            userID = nil
            
        } catch {
            
            print("SIGN OUT FAILED:", error.localizedDescription)
        }
    }
    
    // MARK: - Deinitialization
    
    deinit {
        
        if let authStateHandle {
            
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
    }
    
}
