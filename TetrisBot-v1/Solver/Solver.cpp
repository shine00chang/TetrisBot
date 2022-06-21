//
//  Solver.cpp
//  TetrisBot-v1
//
//  Created by Shine Chang on 6/13/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#include "Solver.hpp"

Solver::Input::Input (int g[20][10], int p) {
    grid = Grid(20, std::vector<Piece_t>(10));
    for (int y=0; y<20; y++)
        for (int x=0; x<10; x++)
            grid[y][x] = static_cast<Piece_t>( g[y][x] );
    piece = static_cast<Piece_t>( p );
};

Solver::Output Solver::solve(Solver::Input input) {
    return Solver::Output(6,2);
};
