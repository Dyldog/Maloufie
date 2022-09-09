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
    @StateObject private var model = ContentViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                layout {
                    FrameView(image: model.frames[0])
                        .edgesIgnoringSafeArea(.all)
//                      .frame(
//                        width: geometry.size.width / 2,
//                        height: geometry.size.height,
//                        alignment: .leading
//                      )
                    FrameView(image: model.frames[1])
                        .edgesIgnoringSafeArea(.all)
//                      .frame(
//                        width: geometry.size.width / 2,
//                        height: geometry.size.height,
//                        alignment: .leading
//                      )
                }
                ErrorView(error: model.error)
                VStack {
                    Spacer()
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
