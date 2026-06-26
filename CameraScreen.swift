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
    
    @State private var intensity: Float = 1.0
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            
            MetalCameraView(
                cameraManager: cameraManager,
                selectedFilter:  selectedFilter,
                intensity: intensity
            )
            .ignoresSafeArea()
            
            
            VStack(spacing: 8) {
                
                if let image = cameraManager.capturedImage {

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                }
            
                HStack(spacing: 12) {
                    
                    ForEach(FilterType.allCases, id: \.self) { filter in
                        
                        Button {
                            
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = filter
                            }
                            
                        } label: {
                            
                            Text(filter.rawValue.capitalized)
                                .font(.caption)
                                .fontWeight(
                                    selectedFilter == filter
                                    ? .semibold
                                    : .regular
                                )
                                .foregroundStyle(
                                    selectedFilter == filter
                                    ? Color.black
                                    : Color.white
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    selectedFilter == filter
                                    ? Color.white
                                    : Color.white.opacity(0.2)
                                )
                                .clipShape(Capsule())
                                .scaleEffect(
                                    selectedFilter == filter ? 1.05 : 1.0
                                )
                                .animation(
                                    .easeInOut(duration: 0.2),
                                    value: selectedFilter
                                )
                                
                        }
                        
                    }
                }
                .frame(maxWidth: .infinity)
                .offset(y: 6)
                
                if selectedFilter.hasIntensity {
                    
                    Slider(
                        value: Binding(
                            get: { Double(intensity) },
                            set: { intensity = Float($0) }
                        ),
                        in: 0...1
                    )
                    .padding(.horizontal)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: selectedFilter)
                }
                
                Spacer()
                    .frame(height: 10)
                
                Button {
                    
                    cameraManager.switchCamera()
                    
                } label: {
                    
                    Label(
                        "Front / Back",
                        systemImage: "camera.rotate"
                    )
                }
                .buttonStyle(.borderedProminent)
                
                Button {

                    cameraManager.capturePhoto(
                        filter: selectedFilter,
                        intensity: intensity
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
