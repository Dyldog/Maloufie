//
//  CGImage+UIImage.swift
//  Maloufie
//
//  Created by Dylan Elliott on 6/9/2022.
//

import Foundation
import UIKit

extension CGImage {
    func uiImage(mirror: Bool = false) -> UIImage {
        .init(cgImage: self, scale: 1, orientation: mirror ? .upMirrored : .up)
    }
}
