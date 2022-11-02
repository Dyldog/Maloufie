//
//  CameraManager.swift
//  Maloufie
//
//  Created by Dylan Elliott on 6/9/2022.
//

import Foundation
import AVFoundation
import UIKit
import Combine

private enum SessionSetupResult {
    case success
    case notAuthorized
    case configurationFailed
    case multiCamNotSupported
}

class CameraManager: ObservableObject {
    
    static var isMulticamSupported: Bool {
        return AVCaptureMultiCamSession.isMultiCamSupported
    }
    
    enum Status {
        case unconfigured
        case configured
        case unauthorized
        case failed
    }
    
    @Published var error: CameraError?
    let session = AVCaptureMultiCamSession()
    
    static let shared: CameraManager = .init()
    
    private let dataOutputQueue = DispatchQueue(label: "com.dylan.SessionQ")
    
    private var frontCameraDeviceInput: AVCaptureDeviceInput?
    private var frontCameraVideoDataOutputConnection: AVCaptureConnection?
    private let frontCameraVideoDataOutput = AVCaptureVideoDataOutput()
    @objc dynamic private(set) var backCameraDeviceInput: AVCaptureDeviceInput?
    private let backCameraVideoDataOutput = AVCaptureVideoDataOutput()
    private var backCameraVideoDataOutputConnection: AVCaptureConnection?
    
    private var setupResult: SessionSetupResult = .success
    
    private var cancellables: Set<AnyCancellable> = .init()
        
    private init() {
        checkPermissions()
        dataOutputQueue.async {
            self.configureSession()
            self.session.startRunning()
        }
        
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification).sink { [weak self] _ in
            self?.frontCameraVideoDataOutputConnection?.videoOrientation = UIDevice.current.orientation.flipped.cameraOrientation
            self?.backCameraVideoDataOutputConnection?.videoOrientation = UIDevice.current.orientation.flipped.cameraOrientation
        }
        .store(in: &cancellables)
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
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
            dataOutputQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { authorized in
                // 3
                if !authorized {
                    self.setupResult = .notAuthorized
                    self.set(error: .deniedAuthorization)
                }
                self.dataOutputQueue.resume()
            }
            // 4
        case .restricted:
            setupResult = .notAuthorized
            set(error: .restrictedAuthorization)
        case .denied:
            setupResult = .notAuthorized
            set(error: .deniedAuthorization)
            // 5
        case .authorized:
            break
            // 6
        @unknown default:
            setupResult = .notAuthorized
            set(error: .unknownAuthorization)
        }
    }
    
    // Must be called on the session queue
    private func configureSession() {
        guard setupResult == .success else { return }
        
        guard AVCaptureMultiCamSession.isMultiCamSupported else {
            print("MultiCam not supported on this device")
            setupResult = .multiCamNotSupported
            set(error: .multiCamNotSupported)
            return
        }
        
        // When using AVCaptureMultiCamSession, it is best to manually add connections from AVCaptureInputs to AVCaptureOutputs
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
            if setupResult == .success {
                checkSystemCost()
            }
        }
        
        guard configureBackCamera() else {
            setupResult = .configurationFailed
            return
        }
        
        guard configureFrontCamera() else {
            setupResult = .configurationFailed
            return
        }
    }
    
    private func configureBackCamera() -> Bool {
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }
        
        // Find the back camera
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Could not find the back camera")
            return false
        }
        
        // Add the back camera input to the session
        do {
            backCameraDeviceInput = try AVCaptureDeviceInput(device: backCamera)
            
            guard let backCameraDeviceInput = backCameraDeviceInput,
                  session.canAddInput(backCameraDeviceInput) else {
                print("Could not add back camera device input")
                return false
            }
            session.addInputWithNoConnections(backCameraDeviceInput)
        } catch {
            print("Could not create back camera device input: \(error)")
            return false
        }
        
        // Find the back camera device input's video port
        guard let backCameraDeviceInput = backCameraDeviceInput,
              let backCameraVideoPort = backCameraDeviceInput.ports(for: .video,
                                                                    sourceDeviceType: backCamera.deviceType,
                                                                    sourceDevicePosition: backCamera.position).first else {
            print("Could not find the back camera device input's video port")
            return false
        }
        
        // Add the back camera video data output
        guard session.canAddOutput(backCameraVideoDataOutput) else {
            print("Could not add the back camera video data output")
            return false
        }
        session.addOutputWithNoConnections(backCameraVideoDataOutput)
        backCameraVideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        
        // Connect the back camera device input to the back camera video data output
        let backCameraVideoDataOutputConnection = AVCaptureConnection(inputPorts: [backCameraVideoPort], output: backCameraVideoDataOutput)
        guard session.canAddConnection(backCameraVideoDataOutputConnection) else {
            print("Could not add a connection to the back camera video data output")
            return false
        }
        session.addConnection(backCameraVideoDataOutputConnection)
        backCameraVideoDataOutputConnection.videoOrientation = .portrait
//        backCameraVideoDataOutputConnection.automaticallyAdjustsVideoMirroring = false
        backCameraVideoDataOutputConnection.isVideoMirrored = true
        
        self.backCameraVideoDataOutputConnection = backCameraVideoDataOutputConnection
        
        return true
    }
    
    private func configureFrontCamera() -> Bool {
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }
        
        // Find the front camera
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("Could not find the front camera")
            return false
        }
        
        // Add the front camera input to the session
        do {
            frontCameraDeviceInput = try AVCaptureDeviceInput(device: frontCamera)
            
            guard let frontCameraDeviceInput = frontCameraDeviceInput,
                  session.canAddInput(frontCameraDeviceInput) else {
                print("Could not add front camera device input")
                return false
            }
            session.addInputWithNoConnections(frontCameraDeviceInput)
        } catch {
            print("Could not create front camera device input: \(error)")
            return false
        }
        
        // Find the front camera device input's video port
        guard let frontCameraDeviceInput = frontCameraDeviceInput,
              let frontCameraVideoPort = frontCameraDeviceInput.ports(for: .video,
                                                                      sourceDeviceType: frontCamera.deviceType,
                                                                      sourceDevicePosition: frontCamera.position).first else {
            print("Could not find the front camera device input's video port")
            return false
        }
        
        // Add the front camera video data output
        guard session.canAddOutput(frontCameraVideoDataOutput) else {
            print("Could not add the front camera video data output")
            return false
        }
        session.addOutputWithNoConnections(frontCameraVideoDataOutput)
        frontCameraVideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        
        // Connect the front camera device input to the front camera video data output
        let frontCameraVideoDataOutputConnection = AVCaptureConnection(inputPorts: [frontCameraVideoPort], output: frontCameraVideoDataOutput)
        guard session.canAddConnection(frontCameraVideoDataOutputConnection) else {
            print("Could not add a connection to the front camera video data output")
            return false
        }
        session.addConnection(frontCameraVideoDataOutputConnection)
        frontCameraVideoDataOutputConnection.videoOrientation = .portrait
//        frontCameraVideoDataOutputConnection.automaticallyAdjustsVideoMirroring = false
        frontCameraVideoDataOutputConnection.isVideoMirrored = true
        
        self.frontCameraVideoDataOutputConnection = frontCameraVideoDataOutputConnection
        
        return true
    }
    
    func set(
        
        _ delegate: AVCaptureVideoDataOutputSampleBufferDelegate,
        for position: AVCaptureDevice.Position,
        queue: DispatchQueue
    ) {
        dataOutputQueue.async {
            switch position {
            case .front: self.frontCameraVideoDataOutput.setSampleBufferDelegate(delegate, queue: queue)
            case .back: self.backCameraVideoDataOutput.setSampleBufferDelegate(delegate, queue: queue)
            default: break
            }
        }
    }
    
    // MARK: - Session Cost Check
    
    struct ExceededCaptureSessionCosts: OptionSet {
        let rawValue: Int
        
        static let systemPressureCost = ExceededCaptureSessionCosts(rawValue: 1 << 0)
        static let hardwareCost = ExceededCaptureSessionCosts(rawValue: 1 << 1)
    }
    
    func checkSystemCost() {
        var exceededSessionCosts: ExceededCaptureSessionCosts = []
        
        if session.systemPressureCost > 1.0 {
            exceededSessionCosts.insert(.systemPressureCost)
        }
        
        if session.hardwareCost > 1.0 {
            exceededSessionCosts.insert(.hardwareCost)
        }
        
        switch exceededSessionCosts {
            
        case .systemPressureCost:
            // Choice #1: Reduce front camera resolution
            if reduceResolutionForCamera(.front) {
                checkSystemCost()
            }
            
            // Choice 2: Reduce the number of video input ports
            else if reduceVideoInputPorts() {
                checkSystemCost()
            }
            
            // Choice #3: Reduce back camera resolution
            else if reduceResolutionForCamera(.back) {
                checkSystemCost()
            }
            
            // Choice #4: Reduce front camera frame rate
            else if reduceFrameRateForCamera(.front) {
                checkSystemCost()
            }
            
            // Choice #5: Reduce frame rate of back camera
            else if reduceFrameRateForCamera(.back) {
                checkSystemCost()
            } else {
                print("Unable to further reduce session cost.")
            }
            
        case .hardwareCost:
            // Choice #1: Reduce front camera resolution
            if reduceResolutionForCamera(.front) {
                checkSystemCost()
            }
            
            // Choice 2: Reduce back camera resolution
            else if reduceResolutionForCamera(.back) {
                checkSystemCost()
            }
            
            // Choice #3: Reduce front camera frame rate
            else if reduceFrameRateForCamera(.front) {
                checkSystemCost()
            }
            
            // Choice #4: Reduce back camera frame rate
            else if reduceFrameRateForCamera(.back) {
                checkSystemCost()
            } else {
                print("Unable to further reduce session cost.")
            }
            
        case [.systemPressureCost, .hardwareCost]:
            // Choice #1: Reduce front camera resolution
            if reduceResolutionForCamera(.front) {
                checkSystemCost()
            }
            
            // Choice #2: Reduce back camera resolution
            else if reduceResolutionForCamera(.back) {
                checkSystemCost()
            }
            
            // Choice #3: Reduce front camera frame rate
            else if reduceFrameRateForCamera(.front) {
                checkSystemCost()
            }
            
            // Choice #4: Reduce back camera frame rate
            else if reduceFrameRateForCamera(.back) {
                checkSystemCost()
            } else {
                print("Unable to further reduce session cost.")
            }
            
        default:
            break
        }
    }
    
    func reduceResolutionForCamera(_ position: AVCaptureDevice.Position) -> Bool {
        for connection in session.connections {
            for inputPort in connection.inputPorts {
                if inputPort.mediaType == .video && inputPort.sourceDevicePosition == position {
                    guard let videoDeviceInput: AVCaptureDeviceInput = inputPort.input as? AVCaptureDeviceInput else {
                        return false
                    }
                    
                    var dims: CMVideoDimensions
                    
                    var width: Int32
                    var height: Int32
                    var activeWidth: Int32
                    var activeHeight: Int32
                    
                    dims = CMVideoFormatDescriptionGetDimensions(videoDeviceInput.device.activeFormat.formatDescription)
                    activeWidth = dims.width
                    activeHeight = dims.height
                    
                    if ( activeHeight <= 480 ) && ( activeWidth <= 640 ) {
                        return false
                    }
                    
                    let formats = videoDeviceInput.device.formats
                    if let formatIndex = formats.firstIndex(of: videoDeviceInput.device.activeFormat) {
                        
                        for index in (0..<formatIndex).reversed() {
                            let format = videoDeviceInput.device.formats[index]
                            if format.isMultiCamSupported {
                                dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                                width = dims.width
                                height = dims.height
                                
                                if width < activeWidth || height < activeHeight {
                                    do {
                                        try videoDeviceInput.device.lockForConfiguration()
                                        videoDeviceInput.device.activeFormat = format
                                        
                                        videoDeviceInput.device.unlockForConfiguration()
                                        
                                        print("reduced width = \(width), reduced height = \(height)")
                                        
                                        return true
                                    } catch {
                                        print("Could not lock device for configuration: \(error)")
                                        
                                        return false
                                    }
                                    
                                } else {
                                    continue
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return false
    }
    
    func reduceFrameRateForCamera(_ position: AVCaptureDevice.Position) -> Bool {
        for connection in session.connections {
            for inputPort in connection.inputPorts {
                
                if inputPort.mediaType == .video && inputPort.sourceDevicePosition == position {
                    guard let videoDeviceInput: AVCaptureDeviceInput = inputPort.input as? AVCaptureDeviceInput else {
                        return false
                    }
                    let activeMinFrameDuration = videoDeviceInput.device.activeVideoMinFrameDuration
                    var activeMaxFrameRate: Double = Double(activeMinFrameDuration.timescale) / Double(activeMinFrameDuration.value)
                    activeMaxFrameRate -= 10.0
                    
                    // Cap the device frame rate to this new max, never allowing it to go below 15 fps
                    if activeMaxFrameRate >= 15.0 {
                        do {
                            try videoDeviceInput.device.lockForConfiguration()
                            videoDeviceInput.videoMinFrameDurationOverride = CMTimeMake(value: 1, timescale: Int32(activeMaxFrameRate))
                            
                            videoDeviceInput.device.unlockForConfiguration()
                            
                            print("reduced fps = \(activeMaxFrameRate)")
                            
                            return true
                        } catch {
                            print("Could not lock device for configuration: \(error)")
                            return false
                        }
                    } else {
                        return false
                    }
                }
            }
        }
        
        return false
    }
    
    func reduceVideoInputPorts () -> Bool {
        var newConnection: AVCaptureConnection
        var result = false
        
        for connection in session.connections {
            for inputPort in connection.inputPorts where inputPort.sourceDeviceType == .builtInDualCamera {
                print("Changing input from dual to single camera")
                
                guard let videoDeviceInput: AVCaptureDeviceInput = inputPort.input as? AVCaptureDeviceInput,
                      let wideCameraPort: AVCaptureInput.Port = videoDeviceInput.ports(for: .video,
                                                                                       sourceDeviceType: .builtInWideAngleCamera,
                                                                                       sourceDevicePosition: videoDeviceInput.device.position).first else {
                    return false
                }
                
                if let previewLayer = connection.videoPreviewLayer {
                    newConnection = AVCaptureConnection(inputPort: wideCameraPort, videoPreviewLayer: previewLayer)
                } else if let savedOutput = connection.output {
                    newConnection = AVCaptureConnection(inputPorts: [wideCameraPort], output: savedOutput)
                } else {
                    continue
                }
                session.beginConfiguration()
                
                session.removeConnection(connection)
                
                if session.canAddConnection(newConnection) {
                    session.addConnection(newConnection)
                    
                    session.commitConfiguration()
                    result = true
                } else {
                    print("Could not add new connection to the session")
                    session.commitConfiguration()
                    return false
                }
            }
        }
        return result
    }
    
    private func setRecommendedFrameRateRangeForPressureState(_ systemPressureState: AVCaptureDevice.SystemPressureState) {
        // The frame rates used here are for demonstrative purposes only for this app.
        // Your frame rate throttling may be different depending on your app's camera configuration.
        let pressureLevel = systemPressureState.level
        if pressureLevel == .serious || pressureLevel == .critical {
            do {
                try self.backCameraDeviceInput?.device.lockForConfiguration()
                
                print("WARNING: Reached elevated system pressure level: \(pressureLevel). Throttling frame rate.")
                
                self.backCameraDeviceInput?.device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 20 )
                self.backCameraDeviceInput?.device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 15 )
                
                self.backCameraDeviceInput?.device.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        } else if pressureLevel == .shutdown {
            print("Session stopped running due to system pressure level.")
        }
    }
}

extension UIDeviceOrientation {
    var flipped: UIDeviceOrientation {
        switch self {
        case .landscapeRight: return .landscapeLeft
        case .landscapeLeft: return .landscapeRight
        default: return .portrait
        }
    }
        
    var cameraOrientation: AVCaptureVideoOrientation {
        switch self {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        default: return .portrait
        }
    }
}
