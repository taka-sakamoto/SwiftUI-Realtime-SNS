//
//  ImageFilterManager.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/05/22.
//

import Foundation
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

final class ImageFilterManager {
    
    static let shared = ImageFilterManager()
    
    private let context = CIContext()
    
    func applyFilter(
        to image: UIImage,
        filter: FilterType,
        intensity: Float
    ) -> UIImage {
        
        guard let ciImage = CIImage(image: image) else {
            return image
        }
        
        switch filter {
            
        case .normal:
            return image
            
        case .sepia,
                .mono,
                .invert:
            
            return MetalFilterManager.shared.applyFilter(
                to: image,
                filter: filter,
                intensity: intensity
            )
        }
    }
    
    private func render (
        _ outputImage: CIImage?,
    original: UIImage
    ) -> UIImage {
        
        guard
            let outputImage,
            let cgImage = context.createCGImage(
                outputImage,
                from: outputImage.extent
            )
        else {
            return original
        }
        
        return UIImage(cgImage: cgImage)
    }
}
