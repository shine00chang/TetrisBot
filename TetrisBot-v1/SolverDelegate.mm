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
    if (game->piece == 0) {
        printf("Invalid piece 0");
        return [[C_SolverOutput alloc] init: 4 r: 0];
    }
    
    Solver::Output output = Solver::solve(Solver::Input(game->grid, game->piece));
    return [[C_SolverOutput alloc] init: output.x r: output.r];
}

@end
