//
//  CameraButton.swift
//  Maloufie
//
//  Created by Dylan Elliott on 6/9/2022.
//

import Foundation
import SwiftUI

struct CameraButton: View {
    let action: () -> Void
    let color: Color = .white
    
    public init(action: @escaping () -> Void) {
        self.action = action
    }
    
    var body: some View {
        Button(action: action, label: {
                ZStack {
                    Circle()
                        .foregroundColor(color)
                    Circle()
                        .foregroundColor(.black)
                        .scaleEffect(0.9)
                    Circle()
                        .foregroundColor(color)
                        .scaleEffect(0.85)
                }
        })
    }
}

struct Previews_CameraButton_Previews: PreviewProvider {
    static var previews: some View {
        CameraButton { }
            .previewLayout(.sizeThatFits)
    }
}
