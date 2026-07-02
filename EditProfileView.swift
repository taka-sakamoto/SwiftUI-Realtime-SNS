//
//  EditProfileView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/07/01.
//

import SwiftUI
import PhotosUI
import UIKit

struct EditProfileView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var viewModel: ProfileViewModel
    
    @State private var displayName = ""
    @State private var bio = ""
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    @State private var isSaving = false

    var body: some View {
        
        NavigationStack {
            
            Form {
                
                Section {
                    
                    HStack {
                        
                        Spacer()
                        
                        PhotosPicker(
                            selection: $selectedItem,
                            matching: .images
                        ) {
                            
                            ZStack(alignment: .bottomTrailing) {
                                
                                ProfileImageView(
                                    imageURL: viewModel.user?.profileImageURL,
                                    selectedImage: selectedImage,
                                    displayName: displayName
                                )
                                .frame(width: 100, height: 100)
                                
                                Image(systemName: "camera.fill")
                                    .padding(8)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                Section("Display Name") {
                    
                    TextField(
                        "Display Name",
                        text: $displayName
                    )
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
                    .disabled(isSaving)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    
                    Button("Save") {
                        
                        Task {
                            
                            isSaving = true
                            
                            defer {
                                isSaving = false
                            }
                            
                            if let selectedImage {
                                await viewModel.updateProfileImage(selectedImage)
                            }
                            
                            await viewModel.updateProfile(
                                displayName: displayName,
                                bio: bio
                            )
                            
                            dismiss()
                        }
                    }
                    .disabled(isSaving)
                }
            }
            
            .onAppear {
                
                displayName = viewModel.user?.displayName ?? ""
                bio = viewModel.user?.bio ?? ""
            }
            
            .onChange(of: selectedItem) { _, newItem in
                
                guard let newItem else {
                    return
                }
                
                Task {
                    
                    do {
                        
                        guard let data = try? await newItem.loadTransferable(type: Data.self),
                              let image = UIImage(data: data) else {
                            return
                        }
                        
                        await MainActor.run {
                            selectedImage = image
                        }
                    }
                }
            }
            .overlay {
                
                if isSaving {
                
                    ZStack {
                        
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()
                        
                        ProgressView("Saving...")
                            .padding(24)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                    }
                }
            }
        }
    }
}


/*
#Preview {
    EditProfileView(
        viewModel: ProfileViewModel()
    )
}
*/
