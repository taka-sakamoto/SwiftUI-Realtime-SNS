//
//  Renderer.swift
//  MetalCameraFilter
//
//  Created by Takayuki Sakamoto on 2026/04/23.
//

import Foundation
import MetalKit
import CoreVideo
import UIKit
import Photos

struct FilterUniforms {
    var filterType: Int32
    var intensity: Float
}


struct AspectUniforms {
    var aspectScale: Float
}


final class Renderer: NSObject, MTKViewDelegate {
    
    var filterType: FilterType = .normal
    var intensity: Float = 1.0
    
    // let videoRecorder = VideoRecorder()
    
    private let device: MTLDevice
    private let commndQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState!
    private var textureCache: CVMetalTextureCache?
    
    var currentTexture: MTLTexture?
    
    var fragmentFunctionName = "monoFragmentShader"
    
    private var currentIntensity: Float = 1.0
    
    private var currentFilter: FilterType = .normal

    
    init(mtkView: MTKView) {
        guard let device = mtkView.device,
              let commandQueue = device.makeCommandQueue()
        else {
            
            #if DEBUG
            print("Faild to setup Metal")
            #endif
            
            self.device = MTLCreateSystemDefaultDevice()!
            self.commndQueue = self.device.makeCommandQueue()!
            
            super.init()
            return
        }
        
        self.device = device
        self.commndQueue = commandQueue
        
        super.init()
        
        CVMetalTextureCacheCreate(
            kCFAllocatorDefault,
            nil,
            device,
            nil,
            &textureCache
        )
        
        buildPipeline()
    }
    
    private func buildPipeline() {
        guard let library = device.makeDefaultLibrary(),
              let vertexFunction = library.makeFunction(name: "vertexShader"),
              let fragmentFunction = library.makeFunction(name: fragmentFunctionName)
        else {
            print("Failed to load shaders")
            return
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            pipelineState = try device.makeRenderPipelineState(
                descriptor: pipelineDescriptor
            )
        } catch {
            print("Failed to create pipeline state: \(error)")
            return
        }
    }
    
    func updateTexture(from pixelBuffer: CVPixelBuffer) {
        guard let textureCache = textureCache else {
            print("Texture cache not found")
            return
        }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        var cvTexture: CVMetalTexture?
        
        let status = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            pixelBuffer,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &cvTexture
        )
        
        if status != kCVReturnSuccess {
            print("Failed to create CVMetalTexture")
            return
        }
        
        guard let cvTexture = cvTexture,
              let texture = CVMetalTextureGetTexture(cvTexture) else {
            print("Failed to get MTLTexture")
            return
        }
        
        self.currentTexture = texture
        
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    func draw(in view: MTKView) {
        
        guard let texture = currentTexture,
              let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commndQueue.makeCommandBuffer(),
              let commandEncoder = commandBuffer.makeRenderCommandEncoder(
                descriptor: renderPassDescriptor
              )
        else {
            return
        }
        
        let textureAspect =
        Float(texture.width) / Float(texture.height)
        
        let viewAspect =
        Float(view.drawableSize.width) /
        Float(view.drawableSize.height)
        
        let aspectScale =
        textureAspect / viewAspect
    
        var uniforms = AspectUniforms(
            aspectScale: aspectScale
        )
         
        commandEncoder.setRenderPipelineState(pipelineState)

        
        commandEncoder.setVertexBytes(
            &uniforms,
            length: MemoryLayout<AspectUniforms>.stride,
            index: 0
        )
        
        
        commandEncoder.setFragmentTexture(
            texture,
            index: 0
        )
        
        var intensity = currentIntensity
        
        commandEncoder.setFragmentBytes(
            &intensity,
            length: MemoryLayout<Float>.stride,
            index: 0
        )

        commandEncoder.drawPrimitives(
            type: .triangleStrip,
            vertexStart: 0,
            vertexCount: 4
        )
        
        commandEncoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
        
    }
    
    func createPixelBuffer(from texture: MTLTexture) -> CVPixelBuffer? {
        let width = texture.width
        let height = texture.height
        
        var pixelBuffer: CVPixelBuffer?
        
        let attrs: [CFString: Any] = [
            kCVPixelBufferMetalCompatibilityKey: true,
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pixelBuffer
        )
        
        guard let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        
        let region = MTLRegionMake2D(0, 0, width, height)
        
        texture.getBytes(
                CVPixelBufferGetBaseAddress(buffer)!,
                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                from: region,
                mipmapLevel: 0
        )
        
        CVPixelBufferUnlockBaseAddress(buffer, [])
    
        return buffer
    }
    
    func setFilter(_ filter: FilterType) {
        
        guard filter != currentFilter else { return }

        currentFilter = filter
        
        switch filter {
            
        case .normal:
            fragmentFunctionName = "fragmentShader"
            
        case .mono:
            fragmentFunctionName = "monoFragmentShader"
            
        case .sepia:
            fragmentFunctionName = "sepiaFragmentShader"
            
        case .invert:
            fragmentFunctionName = "invertFragmentShader"
        }
        
        buildPipeline()
    }
    
    func setIntensity(_ intensity: Float) {
        currentIntensity = intensity
        print("Intensity:", intensity)  // ログ用
    }
    
    func captureCurrentFrame() -> UIImage? {
        
        guard let texture = currentTexture else {
            return nil
        }
        
        let width = texture.width
        let height = texture.height
        
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let byteCount = bytesPerRow * height
        
        var bytes = [UInt8](repeating: 0, count: byteCount)
        
        texture.getBytes(
            &bytes,
            bytesPerRow: bytesPerRow,
            from: MTLRegionMake2D(0, 0, width, height),
            mipmapLevel: 0
        )

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: &bytes,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo:
                CGBitmapInfo.byteOrder32Little.rawValue
            | CGImageAlphaInfo.premultipliedFirst.rawValue
        ),
        let cgImage = context.makeImage()
        else {
            return nil
        }
        
        return UIImage(
            cgImage: cgImage,
            scale: 1.0,
            orientation: .up
        )
                
    }
    
    
}
