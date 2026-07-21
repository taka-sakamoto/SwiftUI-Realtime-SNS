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
    
    @State private var selectedFilter: FilterType
    
    @State private var intensity: Float
    
    @State private var caption = ""
    
    @State private var previewImage: UIImage?
    
    @State private var thumbnails: [FilterType: UIImage] = [:]
    
    let userName: String
    
    let isFromCamera: Bool
    
    init(
        initialImage: UIImage? = nil,
        initialFilter: FilterType = .normal,
        initialIntensity: Float = 1.0,
        userName: String,
        isFromCamera: Bool = false
    ) {
        self.userName = userName
        self.isFromCamera = isFromCamera
    
        _pickedImage = State(
            initialValue: initialImage
        )
        
        _selectedFilter = State(
            initialValue: initialFilter
        )
        
        _intensity = State(
            initialValue: initialIntensity
        )
    }
    
    var body: some View {
        
        NavigationStack {
            
            ScrollView {
                
                VStack(spacing: 20) {
                    
                    if let image = pickedImage {
                        
                        /*
                        let previewImage =
                        ImageFilterManager.shared.applyFilter(
                            to: image,
                            filter: selectedFilter,
                            intensity: intensity
                        )
                         */
                        
                        if let previewImage {
                            
                            Image(uiImage: previewImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 300)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            
                            HStack(spacing: 16) {
                                
                                ForEach(FilterType.allCases, id: \.self) { filter in
                                    VStack(spacing: 8) {
                                        if let thumbnail = thumbnails[filter] {
                                            
                                            Image(uiImage: thumbnail)
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
                    
                    VStack(alignment: .leading, spacing: 8) {
                        
                        Text("Caption")
                            .font(.headline)
                        
                        ZStack(alignment: .topLeading) {
                            
                            if caption.isEmpty {
                                Text("Write a caption...")
                                    .foregroundColor(.secondary)
                                    .padding(.top, 16)
                                    .padding(.leading, 10)
                            }
                            
                            TextEditor(text: $caption)
                                .frame(height: 100)
                                .padding(4)
                        }
                    }
                    .padding(.horizontal)
                    
                    
                    if !isFromCamera {
                        Button("画像を選択") {
                            showPicker = true
                        }
                    }
                    
                    Button("投稿") {
                        
                        guard let image = pickedImage else { return }
                        
                        guard let uid = Auth.auth().currentUser?.uid else { return }
                        
                        let filteredImage =
                        ImageFilterManager.shared.applyFilter(
                            to: image,
                            filter: selectedFilter,
                            intensity: intensity
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
                            name: userName,
                            caption: caption
                        )
                        
                        dismiss()
                    }
                    .disabled(pickedImage == nil)
                    
                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Post")
            .sheet(isPresented: $showPicker) {
                ImagePicker(image: $pickedImage)
            }
        }
        .onAppear {
            updatePreview()
            generateThumbnails()
        }
        .onChange(of: pickedImage) { _ in
            updatePreview()
            generateThumbnails()
        }
        .onChange(of: selectedFilter) { _ in
            updatePreview()
        }
        .onChange(of: intensity) { _ in
            updatePreview()
        }
    }
        
    func uploadImage(
        data: Data,
        uid: String,
        name: String,
        caption: String
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
                        "caption": caption,
                        "filterName": selectedFilter.rawValue,
                        "createdAt": Timestamp(),
                        "likeCount": 0,
                        "commentCount": 0
                    ]) { error in
                        
                    }
                
            }
        }
    }
    
    private func updatePreview() {
        
        guard let image = pickedImage else {
            previewImage = nil
            return
        }
        
        previewImage = ImageFilterManager.shared.applyFilter(
            to: image,
            filter: selectedFilter,
            intensity: intensity
        )
    }
    
    private func generateThumbnails() {
        
        guard let image = pickedImage else {
            thumbnails.removeAll()
            return
        }
        
        var cache: [FilterType: UIImage] = [:]
        
        for filter in FilterType.allCases {
            
            cache[filter] =
            ImageFilterManager.shared.applyFilter(
                to: image,
                filter: filter,
                intensity: 1.0
            )
        }
        
        thumbnails = cache
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
