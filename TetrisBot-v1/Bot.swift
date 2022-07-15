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

let kWeights = 18
let kWeightLabels:[String] = [
    "height",
    "height_H2",
    "height_Q4",
    "holes",
    "hole_depth",
    "hole_depth_sq",
    "clear1",
    "clear2",
    "clear3",
    "clear4",
    "bumpiness",
    "bumpiness_sq",
    "max_well_depth",
    "well_depth",
    "tspin_single",
    "tspin_double",
    "tspin_triple",
    "tspin_completion_sq"
];
let kWeightDefaults:[Double] = [
    0,
    150,
    511,
    400,
    50,
    20,
    -230,
    -200,
    -160,
    4000,
    10,
    20,
    400,
    150,
    -100,
    600,
    100,
    0,
];


class GameData: ObservableObject {
    @Published var grid: [[Piece]] = [];
    @Published var piece: Piece = .None;
    @Published var hold: Piece = .None;
    @Published var newGrid: Bool = false;
    @Published var over: Bool = false;
    @Published var blank: Bool = true;
    
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
    
    @Published var weights: [String];
    @Published var moveWaitTimeInput: String = "0.15";
    
    @State var c_gameData: C_GameData = C_GameData();
    @Published var output: C_SolverOutput = C_SolverOutput(-1,r:-1, hold:false, spin:0);
    
    @Published var waitTimeoutLimitInput = "0.5";
    @Published var waitTimeoutLimit = 0.5;
    @Published var averageSolveTime: Double = 0.0
    
    @Published var errorMessage: String? = nil;

    var lastMoveHadSpin = false;
    var lastMoveTime: UInt64 = 0;
    var moveWaitTime: Double = 0;
    var movesRequested: Int = 0;
    var moveNumber: Int = 0;
    
    init () {
        var weights: [String] = []
        for weightDefault in kWeightDefaults {
            weights.append(String(format: "%f", weightDefault));
        }
        self.weights = weights;
    }
    
 
    static func markGridPoints (for buffer: CVPixelBuffer) {
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
    
    static func getGrid (from buffer: CVPixelBuffer) -> [[Piece]] {
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
    static func getPiece (from buffer: CVPixelBuffer) -> Piece {
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
    static func getHold (from buffer: CVPixelBuffer) -> Piece {
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
        // Preview 1
        // Preview 1 always has one block on 12, 1 or 12, 2.
        pos = Position(x: kGridPos.x + kGridSize*13 + kGridSize/2,
                       y: kGridPos.y + kGridSize    + kGridSize/2)
        greyVal = Int(readPixelBuffer(for: buffer, at: pos))
        piece = greyToPiece(greyVal);
        if (piece != .None && piece != .Garbage) {
            return piece
        }
        pos = Position(x: kGridPos.x + kGridSize*13 + kGridSize/2,
                       y: kGridPos.y + kGridSize*2  + kGridSize/2)
        greyVal = Int(readPixelBuffer(for: buffer, at: pos))
        piece = greyToPiece(greyVal);
        if (piece != .None && piece != .Garbage) {
            return piece
        }
        return .None;
    }
    static func getGame (from buffer: CVPixelBuffer) {
        gameData.grid = getGrid(from: buffer)
        gameData.piece = getPiece(from: buffer)
        gameData.hold = getHold(from: buffer)
    }
    func checkRun () {
        // if game over
        if (gameData.over && !gameData.blank) {
            moveNumber = 0;
            movesRequested = 0;
        }
        // if not over
        if (moveNumber < movesRequested) {
            let timeSinceLastMove = machTimeToSeconds(mach_absolute_time() - lastMoveTime);
            
            // if new frame available
            if (gameData.newGrid) {
                // if last move had spin, drop frame
                if (lastMoveHadSpin) {
                    print("passed, last move had spin");
                    lastMoveHadSpin = false;
                    gameData.newGrid = false;
                    return;
                }
                print("Published Task")
                let delay : Double = max(0, moveWaitTime - timeSinceLastMove);
                if (delay == 0) {
                    runSolverNow();
                    lastMoveTime = mach_absolute_time();
                    moveNumber += 1;
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
                        runSolverNow();
                        lastMoveTime = mach_absolute_time();
                        moveNumber += 1;
                    }
                }
                gameData.newGrid = false;
                // if waited too long (most likely the last frame's output was not properly executed)
            } else if (timeSinceLastMove >= waitTimeoutLimit) {
                print("waited too long, running solver now.");
                runSolverNow();
                lastMoveTime = mach_absolute_time();
                moveNumber += 1;
            }
        }
    }
    
    func runSolverNow () {
        let startTime = mach_absolute_time();
        translateGameData();
        output = SolverDelegate.runSolver(self.c_gameData);
        let solveTime = machTimeToSeconds( mach_absolute_time() - startTime );
        print("Swift received result, got x:\(output.getx()) r:\(output.getr()) hold:\(output.gethold()) spin:\(output.getspin()) after \(solveTime)");
        self.lastMoveHadSpin = output.getspin() == 0 ? false : true;
        PlacePiece(command: output);
        
        self.averageSolveTime = solveTime + self.averageSolveTime / 2.0;
    }

    func runSolverAsync (iterations: Int = 1, delay: Double = 0, first: Bool = true)  {
        if (iterations == 0) {
            return;
        }
        if (first) {
            self.errorMessage = nil;
            print("weight -----")
            for i in 0..<kWeights {
                if let weight = Double(weights[i]) {
                    c_gameData.setWeight(Int32(i), val:weight);
                    print("weight \(i): \(weight)");
                } else {
                    errorMessage = "INVALID WEIGHT. NOT A DOUBLE: \(weights[i])";
                    return;
                }
            }
            if let moveWaitTime = Double(moveWaitTimeInput) {
                self.moveWaitTime = moveWaitTime;
            } else {
                errorMessage = "INVALID WAITTIME. NOT A DOUBLE: \(moveWaitTimeInput)";
                return;
            }
            
            if let waitTimeoutLimit = Double(waitTimeoutLimitInput) {
                self.waitTimeoutLimit = waitTimeoutLimit;
            } else {
                errorMessage = "INVALID TIMEOUT. NOT A DOUBLE: \(waitTimeoutLimitInput)";
                return;
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
            let startTime = mach_absolute_time();
            runSolverNow();
            
            let waitTime = self.moveWaitTime - machTimeToSeconds(mach_absolute_time() - startTime);
            print("wait time: \(waitTime)");
            runSolverAsync(iterations: iterations-1, delay: waitTime, first: false);
        }
    }
    func startPlay(moves: Int = 1) {
        self.movesRequested = moves;
        self.moveNumber = 0;
        self.lastMoveTime = mach_absolute_time();
        
        self.errorMessage = nil;
        print("weight -----")
        for i in 0..<kWeights {
            if let weight = Double(weights[i]) {
                c_gameData.setWeight(Int32(i), val:weight);
                print("weight \(i): \(weight)");
            } else {
                errorMessage = "INVALID WEIGHT. NOT A DOUBLE: \(weights[i])";
                return;
            }
        }
        if let moveWaitTime = Double(moveWaitTimeInput) {
            self.moveWaitTime = moveWaitTime;
        } else {
            errorMessage = "INVALID WAITTIME. NOT A DOUBLE: \(moveWaitTimeInput)";
            return;
        }
        
        if let waitTimeoutLimit = Double(waitTimeoutLimitInput) {
            self.waitTimeoutLimit = waitTimeoutLimit;
        } else {
            errorMessage = "INVALID TIMEOUT. NOT A DOUBLE: \(waitTimeoutLimitInput)";
            return;
        }
    }
    func translateGameData() {
        for y in 0..<20 {
            for x in 0..<10 {
                c_gameData.setGrid(Int32(x), Int32(y), gameData.grid[y][x].rawValue);
            }
        }
        c_gameData.setPiece(gameData.piece.rawValue);
        c_gameData.setHold(gameData.hold.rawValue);
    }
    

    var controlPannelView : some View {
        VStack {
            Text("Solver Control Pannel: ")
                .font(.subheadline)
            HStack (spacing: 10) {
                Button("Run async 1x") {
                    self.runSolverAsync(iterations: 1)
                }
                Button("Run async 20x") {
                    self.runSolverAsync(iterations: 20);

                }
                Button("Run async 120x") {
                    self.runSolverAsync(iterations: 120);
                }
                Button("Run 1x") {
                    self.startPlay(moves: 1);
                }
                Button("Run 20x") {
                    self.startPlay(moves: 20);
                }
                Button("Run 120x") {
                    self.startPlay(moves: 120);
                }
            }
        }
    }
}

extension String: Identifiable {
    public typealias ID = Int
    public var id: Int {
        return hash
    }
}
