//
//  MetalCameraView.swift
//  MetalCameraFilter
//
//  Created by Takayuki Sakamoto on 2026/04/23.
//

import SwiftUI
import MetalKit
import AVFoundation

struct MetalCameraView: UIViewRepresentable {
    
    @ObservedObject var cameraManager: CameraManager
    
    var selectedFilter: FilterType
    
    typealias UIViewType = MTKView
    
    class Coordinator {
        var renderer: Renderer?
        
        init() {}
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported")
            return MTKView()
        }

        let mtkView = MTKView(frame: .zero, device: device)

        mtkView.device = device
        mtkView.framebufferOnly = false
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        
        mtkView.autoResizeDrawable = true
        mtkView.contentMode = .scaleToFill

        if context.coordinator.renderer == nil {
            context.coordinator.renderer = Renderer(mtkView: mtkView)
        }

        mtkView.delegate = context.coordinator.renderer

        cameraManager.renderer = context.coordinator.renderer

        // これを追加
        cameraManager.setupCamera()
        
        print("autoResizeDrawable:", mtkView.autoResizeDrawable)

        return mtkView

    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        
        context.coordinator.renderer?.setFilter(
            selectedFilter
        )
    }
}

/*
#Preview {
    MetalCameraView()
}
*/
