//
//  SolverCtype.cpp
//  TetrisBot-v1
//
//  Created by Shine Chang on 6/24/22.
//  Copyright © 2022 Apple. All rights reserved.
//

// TODO: adapt libSolver with the many updates in solver.
/*
#include <stdio.h>
#include <stdlib.h>
#include "Solver.hpp"

// logs everything
//#define LIBSOLVER_LOG
#ifdef LIBSOLVER_LOG
#define SOLVER_LOG
#endif

struct RetType {
    bool over = false;
    bool hold = false;
    int clears = 0;
};
struct PyWeights {
    int height;
    int height_H2;
    int height_Q4;
    int holes;
    int hole_depth;
    int hole_depth_sq;
    int clear1;
    int clear2;
    int clear3;
    int clear4;
    int bumpiness;
    int bumpiness_sq;
    int max_well_depth;
    int well_depth;
};

extern "C" {
    void solve(int *grid_in, int piece, int hold, double *weights,bool simple, RetType *retVal) {
        int **grid = new int*[20];
        for (int y=0; y<20; y++) {
            grid[y] = new int[10];
            for (int x=0; x<10; x++)
                grid[y][x] = grid_in[y*10 +x];
        }
#ifdef LIBSOLVER_LOG
        Log("LOG-Piece: %d", piece);
        Log("LOG-Grid: \n");
        for (int y=0; y<20; y++) {
            for (int x=0; x<10; x++)
                Log("LOG-%d ", grid[y][x]);
            Log("LOG-\n");
        }
        Log("LOG-created grid\n");
#endif
        
        Input input = Input(grid, piece, hold, weights, simple);
#ifdef LIBSOLVER_LOG
        Log("LOG-created input:\n");
        Log("LOG-input.piece: %d\n", input.piece);
        Log("LOG-input.grid: \n");
        for (int y=0; y<20; y++) {
            for (int x=0; x<10; x++)
                Log("LOG-%d ", input.grid[y][x]);
            Log("LOG-\n");
        }
#endif
        Output *output = Solver::solve(&input, 0, false);
#ifdef LIBSOLVER_LOG
        Log("LOG-Solver returned.\n");
#endif
        if (output == nullptr) {
            Log("LOG-libSolver: received 'nullptr' from solver.\n");
            retVal->over = true;
        } else {
            for (int y=0; y<20; y++)
                for (int x=0; x<10; x++)
                    grid_in[y*10 +x] = static_cast<int>((*output->grid)[y][x]);
#ifdef LIBSOLVER_LOG
            Log("LOG-output.gridInfo.clears: %d\n", output->gridInfo->clears);
            Log("LOG-output.grid: \n");
            for (int y=0; y<20; y++) {
                for (int x=0; x<10; x++)
                    Log("LOG-%d ", grid_in[y*10 +x]);
                Log("LOG-\n");
            }
#endif
            retVal->clears = static_cast<int>(output->gridInfo->clear);
            retVal->hold = output->hold;
        }
    }

    void testStructPointer (RetType *retVal) {
        retVal->clears = 69;
    }
    void freePointer (void* ptr) {
        free(ptr);
    }
    void echo(char* str) {
        Log("LOG-%s", str);
    }
}
*/
