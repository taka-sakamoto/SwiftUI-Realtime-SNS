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
    
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    var currentPosition: AVCaptureDevice.Position = .back
    
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
            position: currentPosition
        ),
        let input = try? AVCaptureDeviceInput(device: device)
        else {
            print("Camera device error")  // ログ用
            session.commitConfiguration()
            return
        }
        
        // input
        if session.inputs.isEmpty,
           session.canAddInput(input) {
            
            session.addInput(input)
            videoDeviceInput = input
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
    
    func switchCamera() {
        
        session.beginConfiguration()
        
        if let currentInput = videoDeviceInput {
            session.removeInput(currentInput)
        }
        
        currentPosition =
            currentPosition == .back
            ? .front
            : .back
        
        guard let newDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: currentPosition
        ) else {
            session.commitConfiguration()
            return
        }
        
        do {
            
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            
            if session.canAddInput(newInput) {
                session.addInput(newInput)
                videoDeviceInput = newInput
                
           }
                
            
        } catch {
            print("switch camera error:", error) // ログ用
        }
        
        if let connection = videoOutput.connection(with: .video) {
            
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
        }
        
        session.commitConfiguration()
    }
    
    func capturePhoto(filter: FilterType) {
        
        guard let image = renderer?.captureCurrentFrame()
        else {
            print("capture failed") // ログ用
            return
        }
        
        let filtered =
            MetalFilterManager.shared.applyFilter(
                to: image,
                filter: filter
            )

        capturedImage = filtered
        
        UIImageWriteToSavedPhotosAlbum(
            filtered,
            nil,
            nil,
            nil
        )
        
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to get pixel buffer") // ログ用
            return
        }
         
        renderer?.updateTexture(from: pixelBuffer)
        
    }
}
