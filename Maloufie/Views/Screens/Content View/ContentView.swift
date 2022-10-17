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
    
    @StateObject private var model = ContentViewModel()
    @State private var expandedFrame: Frame?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                layout {
                    if let image = model.frames[0].unwrapped {
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
                    
                    if let image = model.frames[1].unwrapped {
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
                        CameraButton {
                            self.model.savePhoto()
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: 80, alignment: .center)
                    }
                    
                }
                .padding(.bottom, 30)
            }
        }
        .background(Color.black)
    }
    
    var errorMessage: String? {
        let camera: String
        
        switch (model.frames[0].unwrapped, model.frames[1].unwrapped) {
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
