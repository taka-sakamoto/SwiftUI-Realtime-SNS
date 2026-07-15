//
//  CameraScreen.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/05/27.
//

import SwiftUI

struct CameraScreen: View {
    
    @AppStorage("userName")
    private var userName = ""
    
    @StateObject private var cameraManager = CameraManager()
    
    @State private var selectedFilter: FilterType = .mono
    
    @State private var intensity: Float = 1.0
    
    private let sideButtonSize: CGFloat = 60
    private let shutterButtonSize: CGFloat = 80
   
    @State private var showVideoSavedMessage = false
    
    @State private var showPostUpload = false
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            
            // MARK: - Camera
            MetalCameraView(
                cameraManager: cameraManager,
                selectedFilter:  selectedFilter,
                intensity: intensity
            )
            .ignoresSafeArea()
            
            // MARK: - Top Overlay
            topOverlay
            
            // MARK: - Bottom Controls
            bottomControls
        }
        .onChange(of: cameraManager.didSavedVideo) { saved in
            
            guard saved else { return }
            
            withAnimation {
                showVideoSavedMessage = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                
                withAnimation {
                    showVideoSavedMessage = false
                }
                
                cameraManager.didSavedVideo = false
            }
        }
        .sheet(isPresented: $showPostUpload) {
            
            if let image = cameraManager.capturedImage {
                
                PostUploadView(
                    initialImage: cameraManager.capturedOriginalImage,
                    initialFilter: selectedFilter,
                    initialIntensity: intensity,
                    userName: userName,
                    isFromCamera: true
                )
            }
        }
    }
    
    // MARK: - Top Overlay
    
    private var topOverlay: some View {
        VStack {
            HStack {
                if cameraManager.isRecording {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.red)
                            .frame(width: 10, height: 10)
                        
                        Text("REC")
                            .font(.headline)
                            .bold()
                            .foregroundStyle(.red)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.5))
                    .clipShape(Capsule())
                }
                
                if showVideoSavedMessage {
                    
                    Text("✓ 動画を保存しました")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.7))
                        .clipShape(Capsule())
                        .transition(.opacity)
                }
                
                Spacer()
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack {
            
            Spacer()
            
            previewSection
            
            filterSection
            
            intensitySection
            
            buttonSection
            
        }
    }
    
    // MARK: - Preview
    
    private var previewSection: some View {
        
        VStack(spacing: 12) {
            
            if let image = cameraManager.capturedImage {
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                
                Button {
                    showPostUpload = true
                } label: {
                    Text("投稿")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(.blue)
                        .clipShape(Capsule())
                        
                }
            }
        }
    }

    // MARK: - Filter Section
    
    private var filterSection: some View {
        
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
        
    }

    // MARK: - Intensity Section
    
    private var intensitySection: some View {
        
        Group {
            
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
            
        }
    }
    
    // MARK: - Button Section
    
    private var buttonSection: some View {
        
        HStack {
            
            HStack {
                switchCameraButton
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Shutter
            shutterButton
            
            HStack {
                recordButton
                
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Side Button Style
    
    @ViewBuilder
    private func sideButton<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        
        content()
            .frame(width: sideButtonSize, height: sideButtonSize)
            .background(.black.opacity(0.45))
            .clipShape(Circle())
    }
    
    // MARK: - Switch Camera Button
    
    private var switchCameraButton: some View {
        
        Button {
            
            cameraManager.switchCamera()
             
        } label: {
            
            sideButton {
                
                Image(systemName: "camera.rotate")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
        }
        .disabled(cameraManager.isRecording)
    }
    
    // MARK: - Shutter Button
    
    private var shutterButton: some View {
        
        Button {
            
            cameraManager.capturePhoto(
                filter: selectedFilter,
                intensity: intensity
            )
        } label: {
            
            Circle()
                .fill(.white)
                .frame(
                    width: shutterButtonSize,
                    height: shutterButtonSize
                )
                .overlay {
                    
                    Circle()
                        .stroke(.black, lineWidth: 2)
                        .padding(4)
                }
        }
        .disabled(cameraManager.isRecording)
    }
    
    // MARK: - Record Button
    
    private var recordButton: some View {
    
        Group {
            
            if cameraManager.isRecording {
                
                Button {
                    
                    cameraManager.stopRecording()
                    
                } label: {
                    
                    sideButton {
                        
                        Image(systemName: "stop.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                    }
                }
            } else {
                
                Button {
                    
                    cameraManager.startRecording()
                    
                } label: {
                    
                    sideButton {
                        
                        Image(systemName: "video.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }

}




/*
#Preview {
    CameraScreen()
}
*/
