//
//  VideoRecorder.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/06/29.
//

import Foundation
import AVFoundation

final class VideoRecorder {
    
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    
    private var isWriting = false
    private var startTime: CMTime?
    private var outputURL: URL?
    
    func startRecording(url: URL, size: CGSize) throws {
        
        self.outputURL = url
        
        assetWriter = try AVAssetWriter(
            outputURL: url,
            fileType: .mov
        )
        
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height)
        ]
        
        videoInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: settings
        )
        
        videoInput?.expectsMediaDataInRealTime = true
        
        guard let assetWriter,
              let videoInput else {
            return
        }
        
        if assetWriter.canAdd(videoInput) {
            assetWriter.add(videoInput)
        }
        
        pixelBufferAdaptor =
            AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: videoInput,
                sourcePixelBufferAttributes: [
                    kCVPixelBufferPixelFormatTypeKey as String:
                        kCVPixelFormatType_32BGRA,
                    kCVPixelBufferWidthKey as String:
                        Int(size.width),
                    kCVPixelBufferHeightKey as String:
                        Int(size.height)
                ]
            )
        
        assetWriter.startWriting()
        
        isWriting = true
        startTime = nil
     
    }
    
    func append(pixelBuffer: CVPixelBuffer, at time: CMTime) {
        
        guard isWriting,
              let assetWriter,
              let videoInput,
              let pixelBufferAdaptor else {
            return
        }
        
        // 最初のフレーム
        if startTime == nil {
            
            startTime = time
            
            assetWriter.startSession(atSourceTime: time)
        }
        
        guard videoInput.isReadyForMoreMediaData else {
            return
        }
        
        pixelBufferAdaptor.append(
            pixelBuffer,
            withPresentationTime: time
        )
    }
    
    func finish(completion: @escaping (URL?) -> Void) {
        
        guard let assetWriter else {
            completion(nil)
            return
        }
        
        isWriting = false
        
        videoInput?.markAsFinished()
        
        assetWriter.finishWriting {
            
            DispatchQueue.main.async {
                
                if assetWriter.status == .completed {
                    completion(self.outputURL)
                } else {
                    completion(nil)
                }
            }
        }
        
    }
    
}
