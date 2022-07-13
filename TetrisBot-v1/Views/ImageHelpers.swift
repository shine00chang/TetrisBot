//
//  GrayScaler.swift
//  CaptureSample
//
//  Created by Shine Chang on 5/15/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import CoreVideo
import SwiftUI

extension Color {
    init(red: Int, green: Int, blue: Int) {
        self.init(red: Double(red) / 255.0, green: Double(green) / 255.0, blue: Double(blue) / 255.0, opacity: 1.0)
    }
    init(color: Int) {
        self.init(
            red: (color >> 8) & 0xFF,
            green: (color >> 16) & 0xFF,
            blue: (color >> 24) & 0xFF
        )
    }
}
enum Piece : Int32 {
    case J = 1, L = 2, S = 3, Z = 4, T = 5, I = 6, O = 7, Garbage = 8, None = 0
}
let greyToPieceMap: [Int: Piece] = [
    136: .I,
    135: .I,
    159: .O,
    158: .O,
     75: .J,
     74: .J,
    117: .L,
    118: .L,
    119: .L,
    147: .S,
     84: .Z,
     83: .Z,
     86: .T,
    106: .Garbage,
    107: .Garbage
]
func greyToPiece (_ grey: Int) -> Piece {
    if greyToPieceMap[grey] != nil {
        return greyToPieceMap[grey]!
    }
    return .None
}
let pieceColor: [Piece: Int] = [
    .I: 0xd29a43ff,
    .O: 0x37a1daff,
    .L: 0x2863d4ff,
    .J: 0xbf4424ff,
    .S: 0x34ae70ff,
    .Z: 0x3d2ec6ff,
    .T: 0x8637a1ff,
    .Garbage: 0x6B6B6Bff,
    .None: 0xffffffff
]

func toGrayscale(_ buffer: CVPixelBuffer) {
    CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
    
    if let address = CVPixelBufferGetBaseAddressOfPlane(buffer, 1) {
        let bytesPerRow: Int = CVPixelBufferGetBytesPerRowOfPlane(buffer, 1)
        let bufferWidth = Int(CVPixelBufferGetWidthOfPlane(buffer, 1))
        let bufferHeight = Int(CVPixelBufferGetHeightOfPlane(buffer, 1))
        let constant: UInt64 = 0x8080808080808080
        for y in 0..<bufferHeight {
            for x in 0..<bufferWidth/4 {
                let pixel = address + bytesPerRow * y + x * 8
                pixel.storeBytes(of: constant, as: UInt64.self)
            }
        }
    }
    CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0));
}

func editPixelBuffer (for buffer: CVPixelBuffer, at pos: Position, size: Position, to color: UInt8) {

    CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
    let bytesPerRow: Int = CVPixelBufferGetBytesPerRowOfPlane(buffer, 0)
    let bytesPerPixel = 1
    
    if let baseAddress = CVPixelBufferGetBaseAddress(buffer) {
        for y in 0...size.y {
            for x in 0...size.x {
                let pixel = baseAddress + (pos.y + y) * bytesPerRow + (pos.x + x) * bytesPerPixel
                pixel.storeBytes(of: color, as: UInt8.self)
            }
        }
    }
    CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0));
}
func readPixelBuffer (for buffer: CVPixelBuffer, at pos: Position) -> UInt8 {

    CVPixelBufferLockBaseAddress(buffer, .readOnly)
    let bytesPerRow: Int = CVPixelBufferGetBytesPerRowOfPlane(buffer, 0)
    let bytesPerPixel = 1
    
    var color: UInt8 = 0
    if let baseAddress = CVPixelBufferGetBaseAddress(buffer) {
        let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
        let pixel = pointer + pos.y * bytesPerRow + pos.x * bytesPerPixel
        color = pixel[0]
    }
    CVPixelBufferUnlockBaseAddress(buffer, .readOnly);
    return color
}
func isValidGameFrame (_ frame: FrameData) -> Bool {
    if frame.contentRect.width < 500 ||
        frame.contentRect.height < 715 ||
        frame.contentRect.minX != 0 ||
        frame.contentRect.minY != 0 {
        print("--- INVALID: Check size (500 x 715 minimum) and position (0, 0) ---")
        return false
    }
    return true
}
