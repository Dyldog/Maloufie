//
//  ContentViewModel.swift
//  Maloufie
//
//  Created by Dylan Elliott on 6/9/2022.
//

import Foundation
import CoreImage

class ContentViewModel: ObservableObject {
    @Published private var frontFrame: CGImage?
    @Published private var backFrame: CGImage?
    
    var flipFrames: Bool = false
    
    private var frames: [CGImage?] {
        let frames = [frontFrame, backFrame]
        return flipFrames ? frames.reversed() : frames
    }
    
    var leftFrame: CGImage? { frames[0] }
    var rightFrame: CGImage? { frames[1] }
    
    @Published var error: Error? {
        didSet { print(error) }
    }
    private let cameraManager: CameraManager = .shared
    private let frontFrameManager: FrameManager
    private let backFrameManager: FrameManager
    
    let imageSaver: ImageSaver = .init()
    
    init() {
        frontFrameManager = FrameManager(position: .front, label: "com.dylan.front")
        backFrameManager = FrameManager(position: .back, label: "com.dylan.back")
        setupSubscriptions()
    }
    // 3
    func setupSubscriptions() {
        cameraManager.$error //.merge(with: backCameraManager.$error)
          .receive(on: RunLoop.main)
          .map { $0 }
          .assign(to: &$error)
        
        frontFrameManager.$current
            .receive(on: RunLoop.main)
            .compactMap { buffer in
                return CGImage.create(from: buffer)
            }
            .assign(to: &$frontFrame)
        
        backFrameManager.$current
            .receive(on: RunLoop.main)
            .compactMap { buffer in
                return CGImage.create(from: buffer)
            }
            .assign(to: &$backFrame)
    }
    
    func savePhoto() {
        guard let leftFrame = leftFrame, let rightFrame = rightFrame,
            let merged = leftFrame.uiImage.mergedSideBySide(with: rightFrame.uiImage) else {
            return
        }

        imageSaver.writeToPhotoAlbum(image: merged)
    }
    
    func openPhotos() {
        UIApplication.shared.open(URL(string:"photos-redirect://")!)
    }
}

import UIKit

class ImageSaver: NSObject {
    func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }

    @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        print("Save finished!")
    }
}
