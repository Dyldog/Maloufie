//
//  FrameView.swift
//  Maloufie
//
//  Created by Dylan Elliott on 6/9/2022.
//

import SwiftUI

struct FrameView: View {
    
    var image: CGImage?
    private let label = Text("Camera feed")
    
    var body: some View {
        if let image = image {
          GeometryReader { geometry in
            Image(image, scale: 1.0, orientation: .upMirrored, label: label)
              .resizable()
              .scaledToFill()
              .frame(
                width: geometry.size.width,
                height: geometry.size.height,
                alignment: .center)
              .contentShape(Rectangle())
              .clipped()
          }
        } else {
          Color.black
        }

    }
}
