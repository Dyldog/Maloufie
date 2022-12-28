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
    let enabled: Bool
    var effectiveColor: Color {
        color.opacity(enabled ? 1 : 0.5)
    }
    
    public init(enabled: Bool, action: @escaping () -> Void) {
        self.enabled = enabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action, label: {
                ZStack {
                    Circle()
                        .foregroundColor(effectiveColor)
                    Circle()
                        .foregroundColor(.black)
                        .scaleEffect(0.9)
                    Circle()
                        .foregroundColor(effectiveColor)
                        .scaleEffect(0.85)
                }
        })
        .disabled(!enabled)
    }
}

struct Previews_CameraButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CameraButton(enabled: true) { }
                .previewLayout(.sizeThatFits)
            CameraButton(enabled: false) { }
                .previewLayout(.sizeThatFits)
        }
    }
}
