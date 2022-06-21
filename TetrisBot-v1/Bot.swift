//
//  ImageProcessor .swift
//  CaptureSample
//
//  Created by Shine Chang on 5/11/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import ScreenCaptureKit
import OSLog
import VideoToolbox
import SwiftUI

let kGridPos = Position(x: 244, y: 432)
let kGridSize = 48

class GameData: ObservableObject {
    @Published var grid: [[Piece]] = []
    @Published var piece: Piece = .None
    
    
    init () {
        for _ in 0..<20 {
            let arr: [Piece] = [.None, .None, .None, .None, .None, .None, .None, .None, .None, .None]
            grid.append(arr)
        }
    }
}
class SolverOutput: ObservableObject {
    @Published var message: String = ""
}
func printGrid (_ grid:[[Int]]) {
    for y in 0...19 {
        print(grid[y])
    }
}


class Bot: ObservableObject {
    
    @Published var gameData: GameData = GameData()
    @State var c_gameData: C_GameData = C_GameData()
    @Published var output: C_SolverOutput = C_SolverOutput(-1,r:-1);
    
    @State var initialized : Bool = false
        
    static func markGridPoints (for buffer: CVPixelBuffer) {
        for y in 0...19 {
            for x in 0...9 {
                let pos = Position(x: kGridPos.x + kGridSize*x + kGridSize/2,
                                   y: kGridPos.y + kGridSize*y + kGridSize/2)
                editPixelBuffer(for: buffer, at: pos, size: Position(x: 3,y: 3), to: 255)
            }
        }
    }
    
    func getGrid (from buffer: CVPixelBuffer) -> [[Piece]] {
        var grid: [[Piece]] = []
        var colors: [[Int]] = []
        for y in 0...19 {
            grid.append([])
            colors.append([])
            for x in 0...9 {
                let pos = Position(x: kGridPos.x + kGridSize*x + kGridSize/2,
                                   y: kGridPos.y + kGridSize*y + kGridSize/2)
                let greyVal = Int(readPixelBuffer(for: buffer, at: pos))
                colors[y].append(greyVal)
                grid[y].append(greyToPiece(greyVal))
            }
        }
        //printGrid(colors)
        return grid
    }
    
    func getPiece (from buffer: CVPixelBuffer) -> Piece {
        return gameData.piece;
    }
    func getGame (from buffer: CVPixelBuffer) {
        gameData.grid = getGrid(from: buffer)
        gameData.piece = getPiece(from: buffer)
    }
    func runSolver () {
        translateGameData();
        output = SolverDelegate.runSolver(c_gameData);
        PlacePiece(command: output);
    }
    func translateGameData() {
        for y in 0..<20 {
            for x in 0..<10 {
                c_gameData.setGrid(Int32(x), Int32(y), gameData.grid[y][x].rawValue);
            }
        }
        c_gameData.setPiece(gameData.piece.rawValue);
    }
    
    let blockSize: CGFloat = 10
    var dataView : some View {
        VStack (spacing: 2) {                
            Divider()
            
            Text("Current Piece: \(gameData.piece.rawValue)")
            ForEach (gameData.grid, id: \.self) { row in
                HStack (spacing: 2) {
                    ForEach (row, id: \.self) { cell in
                        Rectangle()
                            .fill(Color(color: pieceColor[cell]!))
                            .frame(width: self.blockSize, height: self.blockSize)
                            .padding(CGFloat(0))
                    }
                }
            }
        }
    }
    var controlPannelView : some View {
        VStack {
            Text("Solver Control Pannel: ")
                .font(.subheadline)
            HStack (spacing: 10) {
                Button("Run") {
                    self.runSolver()
                }
            }
        }
    }
}

func safeShell(_ command: String) throws -> String {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.executableURL = URL(fileURLWithPath: "/bin/zsh")
    task.standardInput = nil

    try task.run()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    
    return output
}
