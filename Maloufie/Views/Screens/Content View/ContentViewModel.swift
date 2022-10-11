//
//  ContentViewModel.swift
//  Maloufie
//
//  Created by Dylan Elliott on 6/9/2022.
//

import Foundation
import CoreImage
import SwiftUI

class ContentViewModel: ObservableObject {
    @Published private var frontFrame: CGImage?
    @Published private var backFrame: CGImage?
    
    @UserDefaultable(key: .layout) private var layout: Layout = .horizontal
    
    var frames: [CGImage?] {
        let frames = [frontFrame, backFrame]
        return layout.isFlipped ? frames.reversed() : frames
    }
    
    var layoutAxis: Axis { layout.axis }
    
    @Published var error: Error?
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
        guard let leftFrame = frames[0], let rightFrame = frames[1],
              let merged = leftFrame.uiImage.mergedSideBySide(with: rightFrame.uiImage, axis: layoutAxis)
        else {
            return
        }

        imageSaver.writeToPhotoAlbum(image: merged)
    }
    
    func openPhotos() {
        UIApplication.shared.open(URL(string:"photos-redirect://")!)
    }
    
    func switchFrame() {
        layout = layout.next
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
