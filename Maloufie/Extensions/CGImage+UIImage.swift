//
//  CGImage+UIImage.swift
//  Maloufie
//
//  Created by Dylan Elliott on 6/9/2022.
//

import Foundation
import UIKit

extension CGImage {
    var uiImage: UIImage { .init(cgImage: self) }
}
