//
//  ContentViewModel.swift
//  Maloufie
//
//  Created by Dylan Elliott on 6/9/2022.
//

import Foundation
import CoreImage
import SwiftUI
import Combine

struct FlippableImage {
    let flipped: Bool
    let image: CGImage
    
    var cgOrientation: CGImagePropertyOrientation {
        flipped ? .upMirrored : .up
    }
    
    var orientation: Image.Orientation {
        switch cgOrientation {
        case .up: return .up
        case .upMirrored: return .upMirrored
        case .down: return .down
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .right: return .right
        case .rightMirrored: return .rightMirrored
        case .left: return .left
        }
    }
    
    init(_ flipped: Bool, _ image: CGImage) {
        self.flipped = flipped
        self.image = image
    }
    
    var unwrapped: (flipped: Bool, image: CGImage)? {
        return (flipped, image)
    }
    
    var uiImage: UIImage? {
        return image.uiImage(mirror: flipped)
    }
}
class ContentViewModel: ObservableObject {
    private var cancellables: Set<AnyCancellable> = .init()
    @Published private var frontFrame: CGImage?
    @Published private var backFrame: CGImage?
    
    @UserDefaultable(key: .layout) private var layout: Layout = .horizontal
    
    var frontImage: FlippableImage? { frontFrame.map { FlippableImage(true, $0) } }
    var backImage: FlippableImage? { backFrame.map { FlippableImage(false, $0) } }
    var frames: [FlippableImage?] {
        let frames: [FlippableImage?] = [frontImage, backImage]
        return layout.isFlipped ? frames.reversed() : frames
    }
    
    var layoutAxis: Axis { layout.axis }
    
    @Published var error: CameraError?
    private let cameraManager: CameraManager = .shared
    private let frontFrameManager: FrameManager
    @Published private var frontHasFace: Bool = false
    private var frontFaceManger: FaceManager?
    private let backFrameManager: FrameManager?
    @Published private var backHasFace: Bool = false
    private var backFaceManger: FaceManager?
    
    let imageSaver: ImageSaver = .init()
    
    private var matchedName: String? = {
        let deviceName = UIDevice.current.name
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: " ", with: "")
            .lowercased()
        let names = ["Aurélien", "Bence", "Audrey", "Naureen", "Swati", "Jess", "Harry", "Harsh", "Sam", "Sim", "Ameera"]
        
        for name in names {
            let sanitised = name
                .folding(options: .diacriticInsensitive, locale: .current)
                .lowercased()
            if deviceName.hasPrefix(sanitised) {
                return name
            }
        }
        
        return nil
        
    }()
    
    var creepyMessage: String {
        guard canTakeImage == false, let matchedName = matchedName else { return "" }
        return "Sorry, \(matchedName), your Malouf score is too low"
    }
    
    var canTakeImage: Bool {
        if matchedName != nil {
            return frontHasFace && backHasFace
        } else {
            return true
        }
    }
    
    init() {
        frontFrameManager = FrameManager(position: .front, label: "com.dylan.front")
        
        if CameraManager.isMulticamSupported {
            backFrameManager = FrameManager(position: .back, label: "com.dylan.back")
        } else {
            backFrameManager = nil
        }
        
        if matchedName != nil {
            frontFaceManger = .init()
            backFaceManger = .init()
        }
        
        setupSubscriptions()
    }
    // 3
    func setupSubscriptions() {
        
        frontFrameManager.$current
            .receive(on: RunLoop.main)
            .compactMap { buffer in
                return CGImage.create(from: buffer)
            }
            .sink { [weak self] in
                self?.frontFrame = $0
                self?.frontFaceManger?.checkForFace($0) { hasFace in
                    self?.frontHasFace = hasFace
                    print("FRONT: \(hasFace ? "FACE" : "NO FACE")")
                }
            }
            .store(in: &cancellables)
        
        backFrameManager?.$current
            .receive(on: RunLoop.main)
            .compactMap { buffer in
                return CGImage.create(from: buffer)
            }
            .sink { [weak self] in
                self?.backFrame = $0
                self?.backFaceManger?.checkForFace($0) { hasFace in
                    self?.backHasFace = hasFace
                    print("BACK: \(hasFace ? "FACE" : "NO FACE")")
                }
            }
            .store(in: &cancellables)
        
        cameraManager.$error
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.error = $0
            }
            .store(in: &cancellables)
    }
    
    func savePhoto() {
        guard let leftImage = frames[0]?.uiImage, let rightImage = frames[1]?.uiImage,
              let merged = leftImage.mergedSideBySide(with: rightImage, axis: layoutAxis)
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
