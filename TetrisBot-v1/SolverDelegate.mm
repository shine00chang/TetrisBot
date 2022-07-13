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
+(C_SolverOutput*) runSolver: (C_GameData*) game {
    
    // Prints grid on "game" variable
    for (int y=0; y<20; y++) {
        char str[20];
        for (int x=0; x<10; x++) {
            str[2*x] = (game->grid[y][x] == 0 ? ' ' : '0' + game->grid[y][x]);
            str[2*x +1] = ' ';
        }
        NSLog(@"%@\n", [NSString stringWithFormat:@"%s", str]);
    }

    // protection
    if (game->piece == 0 || game->piece == 8) {
        printf("Invalid piece 0, returning failsafe move");
        return [[C_SolverOutput alloc] init: 4 r: 0 hold: false spin: 0];
    }
    
    Output *output = Solver::solve(new Input(game->grid, game->piece, game->hold, game->weights));
    if (output == nullptr) {
        printf("Received nullptr from Solver, returning failsafe move");
        return [[C_SolverOutput alloc] init: 4 r: 0 hold: false spin: 0];
    }
    return [[C_SolverOutput alloc] init: output->x r: output->r hold: output->hold spin: output->spin];
}

@end
