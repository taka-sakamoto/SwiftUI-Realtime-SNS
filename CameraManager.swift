//
//  CameraManager.swift
//  MetalCameraFilter
//
//  Created by Takayuki Sakamoto on 2026/04/23.
//

import Foundation
import AVFoundation
import Combine
import UIKit

final class CameraManager: NSObject, ObservableObject {
    
    @Published var capturedImage: UIImage?
    
    let session = AVCaptureSession()
    let videoOutput = AVCaptureVideoDataOutput()
    
    
    weak var renderer: Renderer?
    
    override init() {
        super.init()
    }
    
    func setupCamera() {
        
        if session.isRunning {
            return
        }
        
        session.beginConfiguration()
        session.sessionPreset = .high
        
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ),
        let input = try? AVCaptureDeviceInput(device: device)
        else {
            print("Camera device error")
            session.commitConfiguration()
            return
        }
        
        // input
        if session.inputs.isEmpty,
           session.canAddInput(input) {
            session.addInput(input)
        }
        
        // Output settings
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String:
                kCVPixelFormatType_32BGRA
        ]
        
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        videoOutput.setSampleBufferDelegate(
            self,
            queue: DispatchQueue(label: "camera.frame.queue")
        )
        
        // Output
        if session.outputs.isEmpty,
           session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        // Orientation 重要
        if let connection = videoOutput.connection(with: .video) {
            
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
        }
        
        session.commitConfiguration()
        
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                if !self.session.isRunning {
                    self.session.startRunning()
                }
            }
        }
        
        
    }
    
    func capturePhoto(filter: FilterType) {
        
        guard let image = renderer?.captureCurrentFrame()
        else {
            print("capture failed")
            return
        }
        
        let filtered =
            MetalFilterManager.shared.applyFilter(
                to: image,
                filter: filter
            )

        capturedImage = filtered
        
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to get pixel buffer")
            return
        }
         
        renderer?.updateTexture(from: pixelBuffer)
        
    }
}
