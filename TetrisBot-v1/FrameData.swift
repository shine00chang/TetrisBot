//
//  FrameData.swift
//  TetrisBot-v1
//
//  Created by Shine Chang on 5/21/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import CoreVideo

class FrameData : ObservableObject{
    var pixelBuffer: CVPixelBuffer
    var surface: IOSurface
    var image: CGImage
    var contentRect: CGRect
    var displayTime: TimeInterval
    var contentScale: Double
    var scaleFactor: Double
    
    init (pixelBuffer: CVPixelBuffer,
          surface: IOSurface,
          image: CGImage,
          contentRect: CGRect,
          displayTime: TimeInterval,
          contentScale: Double,
          scaleFactor: Double) {
        self.pixelBuffer = pixelBuffer
        self.surface = surface
        self.image = image
        self.contentRect = contentRect
        self.displayTime = displayTime
        self.contentScale = contentScale
        self.scaleFactor = scaleFactor
    }
}
