//
//  SolverDelegate.m
//  TetrisBot-v1
//
//  Created by Shine Chang on 5/22/22.
//  Copyright © 2022 Apple. All rights reserved.
//


#import <Foundation/Foundation.h>
#include "SolverDelegate.h"

#include "GameData.h"
#include "SolverOutput.h"
#include "Solver/Solver.hpp"

#define SOLVER_LOG

@implementation SolverDelegate
+(C_SolverOutput*) runSolver: (C_GameData*) game pTime:(double)pTime shouldMove:(bool)shouldMove first:(bool)first {
    // Prints grid on "game" variable
    NSLog(@"Solver given board:");
    for (int y=0; y<20; y++) {
        char str[20];
        for (int x=0; x<10; x++) {
            str[2*x] = (game->grid[y][x] == 0 ? ' ' : '0' + game->grid[y][x]);
            str[2*x +1] = ' ';
        }
        NSLog(@"%@\n", [NSString stringWithFormat:@"%s", str]);
    }

    // protection
    if (game->pieces[0] == 0 || game->pieces[0] == 8) {
        NSLog(@"Invalid piece 0, returning failsafe move\n");
        return [[C_SolverOutput alloc] init: 4 r: 0 hold: false spin: 0];
    }
    
    Solver::updatePieceStream(game->pieces, game->hold, first);
    Output *output = Solver::solve(new Input(game->grid, game->weights), pTime, shouldMove, first);
    if (not shouldMove)
        return nullptr;
    if (output == nullptr) {
        NSLog(@"Received nullptr from Solver, returning failsafe move\n");
        return [[C_SolverOutput alloc] init: 4 r: 0 hold: false spin: 0];
    }
    
    C_SolverOutput* ret = [[C_SolverOutput alloc] init: output->x r: output->r hold: output->hold spin: output->spin];
    for (int y=0; y<20; y++)
        for (int x=0; x<10; x++)
            [ret setGrid:x :y val:(int)output->grid[y][x]];
    return ret;
}

@end
