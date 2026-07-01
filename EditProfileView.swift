//
//  EditProfileView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/07/01.
//

import SwiftUI

struct EditProfileView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var viewModel: ProfileViewModel
    
    @State private var displayName = ""
    @State private var bio = ""

    var body: some View {
        
        NavigationStack {
            
            Form {
                
                Section("Display Name") {
                    
                    TextField("Display Name",
                              text: $displayName)
                }
                
                Section("Bio") {
                    
                    TextField(
                        "Introduce yourself",
                        text: $bio,
                        axis: .vertical
                    )
                    .lineLimit(4...8)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            
            .toolbar {
                
                ToolbarItem(placement: .topBarLeading) {
                    
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    
                    Button("Save") {
                        
                        Task {
                            await viewModel.updateProfile(
                                displayName: displayName,
                                bio: bio
                            )
                            
                            dismiss()
                        }
                        
                    }
                }
            }
            
            .onAppear {
                
                displayName = viewModel.user?.displayName ?? ""
                bio = viewModel.user?.bio ?? ""
            }
        }
    }
}


/*
#Preview {
    EditProfileView()
}
*/
