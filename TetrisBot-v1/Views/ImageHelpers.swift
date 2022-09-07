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
    case J = 1, L = 2, S = 3, Z = 4, T = 5, I = 6, O = 7, Garbage = 8, Some = 9, None = 0
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
    .None: 0xffffffff,
    .Some: 0x2b2b2bff,
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



let kGridPos = Position(x: 244, y: 432)
let kGridSize = 48

func markGridPoints (for buffer: CVPixelBuffer) {
    for y in 0...19 {
        for x in 0...9 {
            let pos = Position(x: kGridPos.x + kGridSize*x + kGridSize/2,
                               y: kGridPos.y + kGridSize*y + kGridSize/2)
            editPixelBuffer(for: buffer, at: pos, size: Position(x: 3,y: 3), to: 255)
        }
    }
    var pos = Position(x: kGridPos.x - kGridSize*3,
                       y: kGridPos.y + kGridSize*1 + kGridSize/2);
    editPixelBuffer(for: buffer, at: pos, size: Position(x: 3,y: 3), to: 255);
    pos = Position(x: kGridPos.x - kGridSize*3,
                   y: kGridPos.y + kGridSize*2 + kGridSize/2);
    editPixelBuffer(for: buffer, at: pos, size: Position(x: 3,y: 3), to: 255);
    pos = Position(x: kGridPos.x + kGridSize*12 + kGridSize/2,
                   y: kGridPos.y + kGridSize*1 + kGridSize/2);
    editPixelBuffer(for: buffer, at: pos, size: Position(x: 3,y: 3), to: 255);
    pos = Position(x: kGridPos.x + kGridSize*12 + kGridSize/2,
                   y: kGridPos.y + kGridSize*2 + kGridSize/2);
    editPixelBuffer(for: buffer, at: pos, size: Position(x: 3,y: 3), to: 255);
}

func getGrid (from buffer: CVPixelBuffer) -> [[Piece]] {
    var grid: [[Piece]] = []
    var colors: [[Int]] = []
    gameData.over = true;
    gameData.blank = true;
    
    for y in 0...19 {
        grid.append([])
        colors.append([])
        for x in 0...9 {
            if (y == 0 || y == 1 || y == 2) {
                grid[y].append(.None);
                continue;
            }
            let pos = Position(x: kGridPos.x + kGridSize*x + kGridSize/2,
                               y: kGridPos.y + kGridSize*y + kGridSize/2)
            let greyVal = Int(readPixelBuffer(for: buffer, at: pos))
            colors[y].append(greyVal)
            grid[y].append(greyToPiece(greyVal))
            if (grid[y][x] != gameData.grid[y][x]) {
                gameData.newGrid = true;
            }
            if (grid[y][x] != .None && grid[y][x] != .Garbage) {
                gameData.over = false;
            }
            if (grid[y][x] != .None) {
                gameData.blank = false;
            }
        }
    }
    /*
    print(" --- Bot.getGrid result:")
    if (gameData.newGrid == true) {
        print(" --- NEW: ---");
    }
    printGrid(grid);
    print(" --- ");*/
     
    return grid;
}
func getPiece (from buffer: CVPixelBuffer) -> Piece {
    for y in 0...19 {
        let pos = Position(x: kGridPos.x + kGridSize*4 + kGridSize/2,
                           y: kGridPos.y + kGridSize*y + kGridSize/2)
        let greyVal = Int(readPixelBuffer(for: buffer, at: pos))
        let piece = greyToPiece(greyVal);
        if (piece != .None) {
            gameData.piece = piece;
            break;
        }
    }
    return gameData.piece;
}
func getHold (from buffer: CVPixelBuffer) -> Piece {
    // The hold piece always has one block on -2, 1 or -3, 1, thus, we can look at those two points
    // to identify the hold piece. We do not need a (+kGridSize/2) for the x axis because jstris's
    // UI has an gap between hold piece and board, roughly half of kGridSize.
    var pos = Position(x: kGridPos.x - kGridSize*3,
                       y: kGridPos.y + kGridSize*1 + kGridSize/2)
    var greyVal = Int(readPixelBuffer(for: buffer, at: pos))
    var piece = greyToPiece(greyVal);
    if (piece != .None && piece != .Garbage) {
        return piece
    }
    pos = Position(x: kGridPos.x - kGridSize*3,
                   y: kGridPos.y + kGridSize*2 + kGridSize/2)
    greyVal = Int(readPixelBuffer(for: buffer, at: pos))
    piece = greyToPiece(greyVal);
    if (piece != .None && piece != .Garbage) {
        return piece
    }
    return .None;
}
func getPreviews (from buffer: CVPixelBuffer) -> [Piece] {
    var previews: [Piece] = [];
    // Preview 1 always has one block on 12, 1 or 12, 2.
    for i in 0..<5 {
        var pos = Position(x: kGridPos.x + kGridSize*13        + kGridSize/2,
                           y: kGridPos.y + kGridSize*(i*3 + 1) + kGridSize/2);
        var greyVal = Int(readPixelBuffer(for: buffer, at: pos));
        var piece = greyToPiece(greyVal);
        if (piece != .None && piece != .Garbage) {
            previews.append(piece);
            continue;
        }
        pos = Position(x: kGridPos.x + kGridSize*13         + kGridSize/2,
                       y: kGridPos.y + kGridSize*(i*3 + 2)  + kGridSize/2);
        greyVal = Int(readPixelBuffer(for: buffer, at: pos));
        piece = greyToPiece(greyVal);
        if (piece != .None && piece != .Garbage) {
            previews.append(piece);
            continue;
        }
    }
    return previews;
}
func getGame (from buffer: CVPixelBuffer) {
    gameData.grid = getGrid(from: buffer);
    gameData.piece = getPiece(from: buffer);
    gameData.hold = getHold(from: buffer);
    gameData.previews = getPreviews(from: buffer);
}
