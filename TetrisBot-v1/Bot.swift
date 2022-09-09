//
//  Bot.swift
//  CaptureSample
//
//  Created by Shine Chang on 5/11/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import ScreenCaptureKit
import VideoToolbox
import SwiftUI

class GameData: ObservableObject {
    @Published var grid: [[Piece]] = [];
    @Published var predictionGrid: [[Piece]] = [];
    @Published var piece: Piece = .None;
    @Published var hold: Piece = .None;
    @Published var previews: [Piece] = [];

    var newGrid: Bool = false;
    @Published var over: Bool = false;
    var blank: Bool = true;
    var first = false;
    
    init () {
        for _ in 0..<20 {
            let arr: [Piece] = [.None, .None, .None, .None, .None, .None, .None, .None, .None, .None];
            grid.append(arr);
            predictionGrid.append(arr);
        }
        for _ in 0..<5 {
            previews.append(.None);
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
    
    @Published var moveWaitTimeInput: String = "0.2";
    
    @State var c_gameData: C_GameData = C_GameData();
    
    @Published var waitTimeoutLimitInput = "0.5";
    @Published var waitTimeoutLimit = 0.5;
    @Published var frameWaitTimeInput = "0.1";
    @Published var frameWaitTime = 0.1;
    
    @Published var errorMessage: String? = nil;

    @Published var should_log: Bool = true;
    @Published var useNSLog: Bool = true;
    
    @State var testBool = false
    
    var lastMoveHadSpin = false;
    var lastMoveTime: UInt64 = 0;
    var moveWaitTime: Double = 0;
    var movesRequested: Int = 0;
    var moveNumber: Int = 0;
    var solving: Bool = false;
    
    func checkRun () {
        // if game over
        if (gameData.over && !gameData.blank) {
            moveNumber = 0;
            movesRequested = 0;
        }
        // if not over
        if (moveNumber < movesRequested && !solving) {
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
                Task {
                    runSolver(time: moveNumber == 0 ? moveWaitTime : moveWaitTime - timeSinceLastMove, shouldMove: true);
                }
                gameData.newGrid = false;
                
            // if waited too long (most likely the last frame's output was not properly executed)
            } else if (timeSinceLastMove >= waitTimeoutLimit) {
                print("waited too long, running solver now.");
                runSolver(time: 0, shouldMove: true);
            }
        }
    }
    
    func runSolver(time: Double, shouldMove: Bool) {
        if (solving) {
            print("!!!! --- ERROR: called solver when solving -----")
            return;
        }
        translateGameData();
        self.solving = true;
        
        let output = SolverDelegate.runSolver(self.c_gameData, pTime: time, shouldMove: shouldMove, first: gameData.first);
        gameData.first = false;
        
        if (shouldMove) {
            if let output = output {
                print("Swift received result, got x:\(output.getx()) r:\(output.getr()) hold:\(output.gethold()) spin:\(output.getspin())");
                self.lastMoveHadSpin = output.getspin() == 0 ? false : true;
                
                DispatchQueue.main.async {
                    for y in 0..<20 {
                        for x in 0..<10 {
                            gameData.predictionGrid[y][x] = Piece(rawValue: output.getGrid(Int32(x), Int32(y)))!;
                        }
                    }
                }
                PlacePiece(command: output);
                moveNumber += 1;
                lastMoveTime = mach_absolute_time();
            }
        }
        self.solving = false;
    }

    func startPlay(moves: Int = 1) {
        // Initialize state variables
        self.movesRequested = moves;
        self.moveNumber = 0;
        self.lastMoveTime = mach_absolute_time();
        gameData.first = true;

        // Clear log file
        SolverDelegate.resetSolver();

        // Set time-related configs
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
        // Set Solver configs
        SolverDelegate.loadConfigs();
    }
    func translateGameData() {
        for y in 0..<20 {
            for x in 0..<10 {
                c_gameData.setGrid(Int32(x), Int32(y), gameData.grid[y][x].rawValue);
            }
        }
        c_gameData.setPieces(0, gameData.piece.rawValue);
        for i in 0..<5 {
            c_gameData.setPieces(Int32(i+1), gameData.previews[i].rawValue);
        }
        c_gameData.setHold( gameData.hold.rawValue );
    }
    

    var controlPannelView : some View {
        VStack {
            
            Text("Solver Control Pannel: ")
                .font(.subheadline)
            HStack (spacing: 10) {
                Button("Request Accessibility") {
                    LClick(pos: CGPoint(x: 30, y: 30));
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
