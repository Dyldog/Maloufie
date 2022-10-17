//
//  FrameView.swift
//  Maloufie
//
//  Created by Dylan Elliott on 6/9/2022.
//

import SwiftUI

struct FrameView: View {
    
    var image: (flipped: Bool, image: CGImage)
    private let label = Text("Camera feed")
    
    var body: some View {
        GeometryReader { geometry in
        Image(image.image, scale: 1.0, orientation: image.flipped ? .upMirrored : .up, label: label)
            .resizable()
            .scaledToFill()
            .frame(
              width: geometry.size.width,
              height: geometry.size.height,
              alignment: .center)
            .contentShape(Rectangle())
            .clipped()
        }
    }
}
