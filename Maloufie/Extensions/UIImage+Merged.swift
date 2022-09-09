//
//  UIImage+Merged.swift
//  Maloufie
//
//  Created by Dylan Elliott on 6/9/2022.
//

import UIKit
import SwiftUI

extension UIImage {
    static func width(merging image: UIImage, with other: UIImage, along axis: Axis) -> CGFloat {
        if axis == .horizontal {
            return image.size.width + other.size.width
        } else {
            return max(image.size.width, other.size.width)
        }
    }
    
    static func height(merging image: UIImage, with other: UIImage, along axis: Axis) -> CGFloat {
        if axis == .vertical {
            return image.size.height + other.size.height
        } else {
            return max(image.size.height, other.size.height)
        }
    }
    
    func mergedSideBySide(with otherImage: UIImage, axis: Axis) -> UIImage? {
        let mergedWidth = UIImage.width(merging: self, with: otherImage, along: axis)
        let mergedHeight = UIImage.height(merging: self, with: otherImage, along: axis)
        
        let mergedSize = CGSize(width: mergedWidth, height: mergedHeight)
        
        UIGraphicsBeginImageContext(mergedSize)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        otherImage.draw(
            in: CGRect(
                x: axis == .vertical ? 0 : self.size.width,
                y: axis == .horizontal ? 0 : self.size.height,
                width: otherImage.size.width,
                height: otherImage.size.height
            )
        )
        let mergedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return mergedImage
    }
}
