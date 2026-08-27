//
//  LoginView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/08/25.
//

import SwiftUI

struct LoginView: View {
    
    // MARK: - Dependencies
    
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var profileViewModel: ProfileViewModel
    
    // MARK: - State
    
    @State private var email = ""
    @State private var password = ""
    
    // MARK: - Body
    
    var body: some View {
        
        VStack(spacing: 24) {
            
            Spacer()
            
            // MARK: - Title
            
            VStack(spacing: 8) {
                
                Text("SwiftUI Realtime SNS")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Sign in to continue")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // MARK: - Login Form
            
            VStack(spacing: 16) {
                
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                
                Button("Sign In") {
                    
                    Task {
                        
                        let success = await authViewModel.signIn(
                            email: email,
                            password: password
                        )
                        
                        if success {
                            await profileViewModel.loadOrCreateUser()
                        }
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(.white)
                .background(Color.accentColor)
                .clipShape(
                    RoundedRectangle(cornerRadius: 10)
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}


/*
#Preview {
    LoginView()
}
*/
