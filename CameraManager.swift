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
    
    @Published var capturedOriginalImage: UIImage?
    @Published var capturedImage: UIImage?
    @Published var isRecording = false
    @Published var didSavedVideo = false
    
    let session = AVCaptureSession()
    let videoOutput = AVCaptureVideoDataOutput()
    // private let movieOutput = AVCaptureMovieFileOutput()
    
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    var currentPosition: AVCaptureDevice.Position = .back
    
    weak var renderer: Renderer?
    
    private let videoRecorder = VideoRecorder()
    
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
    
    func capturePhoto(
        filter: FilterType,
        intensity: Float
    ) {
        
        guard let image = renderer?.captureCurrentFrame()
        else {
            print("capture failed") // ログ用
            return
        }
        
        // 投稿編集用の元画像
        capturedOriginalImage = image
                
        let filtered =
            MetalFilterManager.shared.applyFilter(
                to: image,
                filter: filter,
                intensity: intensity
            )

        // カメラプレビュー用
        capturedImage = filtered
        
        // Photos保存用
        UIImageWriteToSavedPhotosAlbum(
            filtered,
            nil,
            nil,
            nil
        )
        
        print(              // デバッグ用
            "original:",
            image.size,
            "filtered:",
            filtered.size
        )
    }
    
    func startRecording() {
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        
        do {
            try videoRecorder.startRecording(
                url: outputURL,
                size: CGSize(width: 1080, height: 1920)
            )
            
            isRecording = true
            
        } catch {
            
            print(error)
            
        }
    }
    
    func stopRecording() {
       
        videoRecorder.finish { [weak self] url in
            
            guard let self else { return }
            
            guard let url else { return }
            
            UISaveVideoAtPathToSavedPhotosAlbum(
                url.path,
                nil,
                nil,
                nil
            )
            
            DispatchQueue.main.async {
                
                self.isRecording = false
                self.didSavedVideo = true
                
            }

        }
        
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
        
        if isRecording,
           let texture = renderer?.currentTexture,
           let filter = renderer?.currentFilter,
           let intensity = renderer?.currentIntensity,
           let filteredTexture = MetalFilterManager.shared.applyFilter(
            to: texture,
            filter: filter,
            intensity: intensity
            ),
           let pixelBuffer = renderer?.createPixelBuffer(from: filteredTexture)
        {
            
            let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
            videoRecorder.append(
                pixelBuffer: pixelBuffer,
                at: time
            )
        }
        
    }
}

