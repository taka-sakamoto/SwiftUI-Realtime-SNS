//
//  MetalFilterManager.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/05/24.
//

import Foundation
import UIKit
import Metal
import MetalKit

final class MetalFilterManager {
    
    static let shared = MetalFilterManager()
    
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    
    private let textureLoader: MTKTextureLoader
    private var pipelineState: MTLRenderPipelineState!
    
    var fragmentFunctionName: String = "invertFragmentShader"
    
    private init() {
        
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue()
        else {
            fatalError("Metal setup failed")
        }
        
        self.device = device
        self.commandQueue = commandQueue
        
        self.textureLoader = MTKTextureLoader(device: device)
        
        buildPipeline()
        
    }
    
    func applyFilter(
        to image: UIImage,
        filter: FilterType
    ) -> UIImage {
        
        let normalized = normalizedImage(image)
        
        switch filter {
            
        case .invert:
            fragmentFunctionName = "invertFragmentShader"
            
        case .mono:
            fragmentFunctionName = "monoFragmentShader"
            
        case .sepia:
            fragmentFunctionName = "sepiaFragmentShader"
            
        case .normal:
            return image
        }
        
        buildPipeline()
        
        guard let cgImage = normalized.cgImage else {
            return image
        }
        
        let width = cgImage.width
        let height = cgImage.height
        
        guard let inputTexture =
                try? textureLoader.newTexture(
                    cgImage: cgImage,
                    options: [
                        MTKTextureLoader.Option.SRGB : true
                    ]
                )
        else {
            return image
        }
        
        let textureDescriptor =
        MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm_srgb,
            width: width,
            height: height,
            mipmapped: false
        )
        
        textureDescriptor.storageMode = .shared
        
        textureDescriptor.usage = [
            .renderTarget,
            .shaderRead
        ]
        
        guard let outputTexture =
                device.makeTexture(descriptor: textureDescriptor)
        else {
            return image
            
        }
        
                
       guard let commandBuffer =
                commandQueue.makeCommandBuffer()
        else {
            return image
        }
        
        print(outputTexture.pixelFormat.rawValue)
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        
        renderPassDescriptor.colorAttachments[0].texture = outputTexture
        
        renderPassDescriptor.colorAttachments[0].clearColor =
        MTLClearColorMake(0, 0, 0, 1)
        
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        guard let encoder =
                commandBuffer.makeRenderCommandEncoder(
                    descriptor: renderPassDescriptor
                )
        else {
            return image

        }
        
        encoder.setRenderPipelineState(pipelineState)
        
        encoder.setFragmentTexture(inputTexture, index: 0)
        
        encoder.drawPrimitives(
            type: .triangleStrip,
            vertexStart: 0,
            vertexCount: 4
        )
        
        encoder.endEncoding()
        
        commandBuffer.commit()
        
        commandBuffer.waitUntilCompleted()
        
        let bytePerPixel = 4
        let bytesPerRow = bytePerPixel * width
        let byteCount = bytesPerRow * height
        
        var bytes = [UInt8](repeating: 0, count: byteCount)
        
        outputTexture.getBytes(
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
        let outputCGImage = context.makeImage()
        else {
            return image
        }
        
        return UIImage(cgImage: outputCGImage)
    }
    
    private func buildPipeline() {
        
        guard let library = device.makeDefaultLibrary() else {
            fatalError("library nil")
        }
        
        guard let vartexFunction =
                library.makeFunction(name: "vertexShader")
        else {
            fatalError("vertexShader nil")
        }
        
        guard let fragmentFunction =
                library.makeFunction(name: fragmentFunctionName)
        else {
            fatalError("fragment nil")
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        
        pipelineDescriptor.vertexFunction = vartexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
         
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        
        do {
            
            self.pipelineState =
            try device.makeRenderPipelineState(
                descriptor: pipelineDescriptor
            )
        } catch {
            
            fatalError(error.localizedDescription)
        }
    }
    
    private func normalizedImage(_ image: UIImage) -> UIImage {
        
        if image.imageOrientation == .up {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(
            image.size,
            false,
            image.scale
        )
        
        image.draw(in: CGRect(origin: .zero, size: image.size))
        
        let normalized =
            UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return normalized ?? image
        
    }
}
