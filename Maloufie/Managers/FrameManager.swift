//
//  FrameManager.swift
//  Maloufie
//
//  Created by Dylan Elliott on 6/9/2022.
//

import Foundation
import AVFoundation
// 1
class FrameManager: NSObject, ObservableObject {
    @Published var current: CVPixelBuffer?
    // 4
    let videoOutputQueue: DispatchQueue
    
    init(position: AVCaptureDevice.Position, label: String) {
        videoOutputQueue = DispatchQueue(
            label: label,
            qos: .userInitiated,
            attributes: [],
            autoreleaseFrequency: .workItem)
        // 5
        super.init()
        CameraManager.shared.set(self, for: position, queue: videoOutputQueue)
    }
}

extension FrameManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        if let buffer = sampleBuffer.imageBuffer {
            DispatchQueue.main.async {
                self.current = buffer
            }
        }
    }
}
