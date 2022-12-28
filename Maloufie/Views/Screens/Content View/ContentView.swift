//
//  ContentView.swift
//  Maloufie
//
//  Created by Dylan Elliott on 6/9/2022.
//

import SwiftUI

extension CaseIterable {
    var allCasesCount: Int { type(of: self).allCases.count }
}

extension CaseIterable where Self: RawRepresentable, RawValue == Int {
    var next: Layout {
        .init(rawValue: (rawValue + 1) % allCasesCount)!
    }
}

enum Layout: Int, CaseIterable, Codable {
    case vertical
    case horizontal
    case verticalFlipped
    case horizontalFlipped
    
    var isFlipped: Bool {
        switch self {
        case .horizontal, .vertical: return false
        case .horizontalFlipped, .verticalFlipped: return true
        }
    }
    
    var axis: Axis {
        switch self {
        case .vertical, .verticalFlipped: return .vertical
        case .horizontal, .horizontalFlipped: return .horizontal
        }
    }
}

struct ContentView: View {
    enum Frame {
        case a
        case b
    }
    
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var model = ContentViewModel()
    @State private var expandedFrame: Frame?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                layout {
                    if let image = model.frames[0] {
                        FrameView(image: image)
                            .edgesIgnoringSafeArea(.all)
                            .gesture(
                                DragGesture(minimumDistance: 0).onChanged { _ in
                                    expandedFrame = .a
                                }.onEnded { _ in
                                    expandedFrame = nil
                                }
                            )
                            .frame(
                                width: width(for: .a, with: geometry),
                                height: height(for: .a, with: geometry)
                            )
                    }
                    
                    if let image = model.frames[1] {
                        FrameView(image: image)
                            .edgesIgnoringSafeArea(.all)
                            .gesture(
                                DragGesture(minimumDistance: 0).onChanged { _ in
                                    expandedFrame = .b
                                }.onEnded { _ in
                                    expandedFrame = nil
                                }
                            )
                            .frame(
                                width: width(for: .b, with: geometry),
                                height: height(for: .b, with: geometry)
                            )
                    }
                }
                ErrorView(error: model.error)
                VStack {
                    Spacer()
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .font(.footnote)
                            .padding()
                    }
                    ZStack {
                        HStack {
                            IconButton(imageName: "photo.on.rectangle") {
                                self.model.openPhotos()
                            }
                            
                            Spacer()
                            
                            IconButton(imageName: "arrow.triangle.2.circlepath") {
                                self.model.switchFrame()
                            }

                        }
                        .padding(.horizontal, 20)
                        CameraButton(enabled: self.model.canTakeImage) {
                            self.model.savePhoto()
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: 80, alignment: .center)
                    }
                    
                }
                .padding(.bottom, 30)
                
                VStack {
                    Spacer()
                    Text(model.creepyMessage)
                        .foregroundColor(.white)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                }
            }
        }
        .background(Color.black)
        .onChange(of: scenePhase) { newPhase in
            expandedFrame = nil
        }
    }
    
    func message(for error: CameraError) -> String {
        switch error {
        case .multiCamNotSupported:
            return "Unfortunately, multi-cam functionality is not supported on your device. We don't want to tell you to upgrade your phone if you're otherwise happy with it, but you unfortunately won't be able to use Maloufie on this one. Sorry :("
        case .cameraUnavailable, .cannotAddInput, .cannotAddOutput, .createCaptureInput:
            return "Unfortunately, we can't access the camera. We're not exactly sure why, but it can't be good!"
        case .deniedAuthorization, .restrictedAuthorization, .unknownAuthorization:
            return "You have denied access to the camera for this app. Not much a camera app can do without that, eh? Enable camera access and maybe we can talk."
        }
    }
    
    var errorMessage: String? {
        if let error = model.error {
            return message(for: error)
        }
        let camera: String
        
        switch (model.frames[0], model.frames[1]) {
        case (.some, .some): return nil
        case (.some, nil), (nil, .some): camera = "one of the cameras has"
        case (nil, nil): camera = "both of the cameras have"
        }
        
        return "Unfortunately, it seems that \(camera) crashed. Contact the developer and request a very large cookie!"
    }
    
    private func width(for frame: Frame, with geometry: GeometryProxy) -> CGFloat? {
        guard let expandedFrame = expandedFrame else { return nil }
        guard expandedFrame == frame else { return 0 }
        return geometry.size.width
    }
    
    private func height(for frame: Frame, with geometry: GeometryProxy) -> CGFloat? {
        guard let expandedFrame = expandedFrame else { return nil }
        guard expandedFrame == frame else { return 0 }
        return geometry.size.height
    }
    
    private func layout<Content: View>(@ViewBuilder content: () -> Content) -> AnyView {
        switch model.layoutAxis {
        case .horizontal: return AnyView(HStack(spacing: 0) { content() })
        case .vertical: return AnyView(VStack(spacing: 0) { content() })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
