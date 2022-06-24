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
func printGrid (_ grid:[[Piece]]) {
    for y in 0...19 {
        var str = "";
        for x in 0...9 {
            if (grid[y][x] != .None) {
                str += "\(grid[y][x].rawValue) ";
            } else {
                str += "  ";
            }
        }
        print(str);
    }
}


class Bot: ObservableObject {
    
    @Published var gameData: GameData = GameData()
    @State var c_gameData: C_GameData = C_GameData()
    @Published var output: C_SolverOutput = C_SolverOutput(-1,r:-1);
    
    @State var initialized : Bool = false
    @Published var averageSolveTime: Double = 0.0

    // Wait time between moves (in seconds)
    let moveDelay: Double = 1.0 / 10
 
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
                if (y == 0 || y == 1) {
                    grid[y].append(.None);
                    continue;
                }
                let pos = Position(x: kGridPos.x + kGridSize*x + kGridSize/2,
                                   y: kGridPos.y + kGridSize*y + kGridSize/2)
                let greyVal = Int(readPixelBuffer(for: buffer, at: pos))
                colors[y].append(greyVal)
                grid[y].append(greyToPiece(greyVal))
            }
        }
        print(" --- Bot.getGrid result:")
        printGrid(grid)
        print(" --- ")
        return grid
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
    func getGame (from buffer: CVPixelBuffer) {
        self.gameData.grid = getGrid(from: buffer)
        self.gameData.piece = getPiece(from: buffer)
    }
    func runSolver (iterations: Int = 0, delay: Double = 0) async {
        if (iterations == 0) {
            return;
        }
            
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
            
            let startTime = mach_absolute_time();
            print("Swift invoked Solver at \(DispatchTime.now().uptimeNanoseconds / 1_000_000_000), awaiting result...");

            translateGameData();
            output = SolverDelegate.runSolver(self.c_gameData);
            let solveTime = machTimeToSeconds( mach_absolute_time() - startTime );
            print("Swift received result, got x:\(output.getx()) r:\(output.getr()) after \(solveTime)");

            PlacePiece(command: output);
            
            let elapsedTime = machTimeToSeconds( mach_absolute_time() - startTime );
            self.averageSolveTime = solveTime + self.averageSolveTime / 2.0;
            
            let waitTime = self.moveDelay - elapsedTime;
            print("wait time: \(waitTime)");
            Task.init {
                await runSolver(iterations: iterations-1, delay: waitTime);
            }
        }
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
                Button("Run 1x") {
                    Task.init {
                        await self.runSolver(iterations: 1)
                    }
                }
                Button("Run 20x") {
                    Task.init {
                        await self.runSolver(iterations: 20);
                    }
                }
                Button("Run 120x") {
                    Task.init {
                        await self.runSolver(iterations: 120);
                    }
                }
            }
        }
    }
}
