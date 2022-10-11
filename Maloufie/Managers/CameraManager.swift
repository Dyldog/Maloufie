//
//  CameraManager.swift
//  Maloufie
//
//  Created by Dylan Elliott on 6/9/2022.
//

import Foundation
import AVFoundation

class CameraManager: ObservableObject {
    
    enum Status {
        case unconfigured
        case configured
        case unauthorized
        case failed
    }
    
    @Published var error: CameraError?
    let session = AVCaptureMultiCamSession()
    
    static let shared: CameraManager = .init()
    
    private let sessionQueue = DispatchQueue(label: "com.dylan.SessionQ")
    var frontVideoDataOutput: AVCaptureVideoDataOutput?
    var backVideoDataOutput: AVCaptureVideoDataOutput?
    
    var hasSetupFrontCamera: Bool {
        frontVideoDataOutput != nil
    }
    
    var hasSetupBackCamera: Bool {
        backVideoDataOutput != nil
    }
    
    private var status = Status.unconfigured
    
    private init() {
        configure()
    }
    
    private func configure() {
        checkPermissions()
        sessionQueue.async {
            self.configureCaptureSession()
            self.session.startRunning()
        }
    }
    
    private func set(error: CameraError?) {
        DispatchQueue.main.async {
            self.error = error
        }
    }
    
    private func checkPermissions() {
        // 1
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            // 2
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { authorized in
                // 3
                if !authorized {
                    self.status = .unauthorized
                    self.set(error: .deniedAuthorization)
                }
                self.sessionQueue.resume()
            }
            // 4
        case .restricted:
            status = .unauthorized
            set(error: .restrictedAuthorization)
        case .denied:
            status = .unauthorized
            set(error: .deniedAuthorization)
            // 5
        case .authorized:
            break
            // 6
        @unknown default:
            status = .unauthorized
            set(error: .unknownAuthorization)
        }
    }
    
    private func configureCaptureSession() {
        guard status == .unconfigured else {
            return
        }
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }
        
        frontVideoDataOutput = addCamera(.front)
        backVideoDataOutput = addCamera(.back)
        status = .configured
    }
    
    private func addCamera(_ position: AVCaptureDevice.Position) -> AVCaptureVideoDataOutput? {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            print("no camera")
            return nil
        }
        
        let deviceInput: AVCaptureDeviceInput
        do {
            deviceInput = try AVCaptureDeviceInput(device: camera)
            session.addInputWithNoConnections(deviceInput)
        } catch {
            print("no front input: \(error)")
            return nil
        }
        
        guard let videoPort = deviceInput.ports(for: .video, sourceDeviceType: camera.deviceType, sourceDevicePosition: camera.position).first else {
            print("no front camera device input's video port")
            return nil
        }
        
        let output = AVCaptureVideoDataOutput()
        
        // append front video output to dual video session
        guard session.canAddOutput(output) else {
            print("no camera video output")
            return nil
        }
        
        session.addOutputWithNoConnections(output)
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        
        // connect front output to dual video session
        let outputConnection = AVCaptureConnection(inputPorts: [videoPort], output: output)
        guard session.canAddConnection(outputConnection) else {
            print("no connection to the video output")
            return nil
        }
        session.addConnection(outputConnection)
        outputConnection.videoOrientation = .portrait
        outputConnection.isVideoMirrored = true
        
        return output
    }
    
    func set(
        
        _ delegate: AVCaptureVideoDataOutputSampleBufferDelegate,
        for position: AVCaptureDevice.Position,
        queue: DispatchQueue
    ) {
        sessionQueue.async {
            switch position {
            case .front: self.frontVideoDataOutput?.setSampleBufferDelegate(delegate, queue: queue)
            case .back: self.backVideoDataOutput?.setSampleBufferDelegate(delegate, queue: queue)
            default: break
            }
        }
    }
}
