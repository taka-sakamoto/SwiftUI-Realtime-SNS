//
//  PostUploadView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/05/22.
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct PostUploadView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var showPicker = false
    @State private var pickedImage: UIImage?
    
    @State private var selectedFilter: FilterType = .normal
    
    @State private var intensity: Float = 1.0
    
    let userName: String
    
    var body: some View {
        
        NavigationStack {
            
            VStack(spacing: 20) {
                
                if let image = pickedImage {
                    
                    Image(
                        uiImage: ImageFilterManager.shared.applyFilter(
                            to: image,
                            filter: selectedFilter,
                            intensity: 1.0
                        )
                    )
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
              
                
                    ScrollView(.horizontal, showsIndicators: false) {
                    
                        HStack(spacing: 16) {
                        
                            ForEach(FilterType.allCases, id: \.self) { filter in
                                
                                let previewImage =
                                ImageFilterManager.shared.applyFilter(
                                    to: image,
                                    filter: filter,
                                    intensity: 1.0
                                )
                                
                                VStack(spacing: 8) {
                                    
                                    Image(uiImage: previewImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay {
                                            
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    selectedFilter == filter
                                                    ? Color.blue
                                                    : Color.clear,
                                                    lineWidth: 3
                                                )
                                        }
                                    
                                    Text(filter.rawValue.capitalized)
                                        .font(.caption)
                                }
                                .onTapGesture {
                                    selectedFilter = filter
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Button("画像を選択") {
                    showPicker = true
                }
                
                Button("投稿") {
                    
                    guard let image = pickedImage else { return }
                    
                    guard let uid = Auth.auth().currentUser?.uid else { return }
                    
                    let filteredImage =
                    ImageFilterManager.shared.applyFilter(
                        to: image,
                        filter: selectedFilter,
                        intensity: 1.0
                    )
                    
                    let resizedImage = filteredImage.resized(toWidth: 720)
                    
                    guard let data =
                            resizedImage.jpegData(compressionQuality: 0.6)
                    else {
                        return
                    }
                    
                    print(  // デバッグ
                        "Upload image size:",
                        data.count / 1024,
                        "KB"
                    )  // ここまで

                    uploadImage(
                        data: data,
                        uid: uid,
                        name: userName
                    )
                    
                    dismiss()
                }
                .disabled(pickedImage == nil)
                
                Spacer()
            }
            .navigationTitle("New Post")
            .sheet(isPresented: $showPicker) {
                ImagePicker(image: $pickedImage)
            }
        }
    }
        
    func uploadImage(
        data: Data,
        uid: String,
        name: String
    ) {
        
        let storageRef = Storage.storage()
            .reference()
            .child("images/\(UUID().uuidString).jpg")
        
        storageRef.putData(data) { _, error in
            
            if let error = error {
                print("Storage upload error:", error)
                return
            }
            
            storageRef.downloadURL { url, error in
                
                if let error = error {
                    
                    return
                }
                
                guard let imageUrl = url?.absoluteString else {
                    return
                }
                
                Firestore.firestore()
                    .collection("posts")
                    .addDocument(data: [
                        
                        "imageUrl": imageUrl,
                        "userId": uid,
                        "userName": name,
                        "filterName": selectedFilter.rawValue,
                        "createdAt": Timestamp(),
                        "likeCount": 0,
                        "commentCount": 0
                    ]) { error in
                        
                    }
                
            }
        }
    }
    
}

extension UIImage {

    func resized(toWidth width: CGFloat) -> UIImage {

        let scale = width / size.width

        let height = size.height * scale

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(
            size: CGSize(
                width: width,
                height: height
            ),
            format: format
        )

        return renderer.image { _ in
            
            self.draw(
                in: CGRect(
                    x: 0,
                    y: 0,
                    width: width,
                    height: height
                )
            )
        }
    }
}


/*
#Preview {
    PostUploadView()
}
*/
