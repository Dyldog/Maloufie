//
//  IconButton.swift
//  Maloufie
//
//  Created by Dylan Elliott on 6/9/2022.
//

import Foundation
import SwiftUI

struct IconButton: View {
    let imageName: String
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                Circle()
                    .foregroundColor(.gray)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: 40)
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .tint(.white)
                    .frame(width: 25)
                    .fixedSize()
                    .padding()
            }
        }
    }
}
