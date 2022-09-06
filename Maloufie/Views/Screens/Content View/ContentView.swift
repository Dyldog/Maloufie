//
//  ContentView.swift
//  Maloufie
//
//  Created by Dylan Elliott on 6/9/2022.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var model = ContentViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                HStack(spacing: 0) {
                    FrameView(image: model.leftFrame)
                        .edgesIgnoringSafeArea(.all)
                      .frame(
                        width: geometry.size.width / 2,
                        height: geometry.size.height,
                        alignment: .leading
                      )
                    FrameView(image: model.rightFrame)
                        .edgesIgnoringSafeArea(.all)
                      .frame(
                        width: geometry.size.width / 2,
                        height: geometry.size.height,
                        alignment: .leading
                      )
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
                                self.model.flipFrames.toggle()
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
