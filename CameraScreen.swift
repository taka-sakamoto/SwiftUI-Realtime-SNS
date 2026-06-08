//
//  CameraScreen.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/05/27.
//

import SwiftUI

struct CameraScreen: View {
    
    @StateObject private var cameraManager = CameraManager()
    
    @State private var selectedFilter: FilterType = .mono
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            
            MetalCameraView(
                cameraManager: cameraManager,
                selectedFilter:  selectedFilter
            )
            .ignoresSafeArea()
            
            
            VStack(spacing: 24) {
                
                if let image = cameraManager.capturedImage {

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                }
            
                ScrollView(.horizontal, showsIndicators: false) {
                
                    HStack(spacing: 16) {
                    
                        ForEach(FilterType.allCases, id: \.self) { filter in
                      
                            VStack(spacing: 8) {
                                
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        selectedFilter == filter
                                        ? Color.blue
                                        : Color.gray.opacity(0.3)
                                    )
                                    .frame(width: 70, height: 70)
                        
                                Text(filter.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(.white)
                            }
                            .onTapGesture {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding()
                }
                
                Button {
                    print("button tapped")

                    //print("capture")
                    cameraManager.capturePhoto(
                        filter: selectedFilter
                    )
                    
                } label: {
                    
                    Circle()
                        .fill(.white)
                        .frame(width: 80, height: 80)
                        .overlay {
                            
                            Circle()
                                .stroke(.black, lineWidth: 2)
                                .padding(4)
                        }
                }
                .padding()
            }
        }
    }
    
}


/*
#Preview {
    CameraScreen()
}
*/
