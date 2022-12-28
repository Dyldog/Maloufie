//
//  FaceManager.swift
//  Maloufie
//
//  Created by Dylan Elliott on 28/12/2022.
//

import Foundation
import CoreGraphics
import Vision

class FaceManager {
    var requestHandler: VNImageRequestHandler?
    
    var isProcessing: Bool { requestHandler != nil }
    func checkForFace(_ image: CGImage, completion: @escaping (Bool) -> Void) {
        guard isProcessing == false else { return }
        requestHandler = VNImageRequestHandler(cgImage: image,
                                               orientation: .up,
                                                        options: [:])
        
        let request = VNDetectFaceRectanglesRequest { request, error in
            let results = (request.results as? [VNFaceObservation]) ?? []
            self.requestHandler = nil
            DispatchQueue.main.async {
                completion(!results.isEmpty)
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.requestHandler?.perform([request])
            } catch let error as NSError {
                print("Failed to perform image request: \(error)")
                self.requestHandler = nil
                return
            }
        }
    }
}
