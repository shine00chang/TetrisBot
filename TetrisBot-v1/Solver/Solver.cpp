//
//  Solver.cpp
//  TetrisBot-v1
//
//  Created by Shine Chang on 6/13/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#include "Solver.hpp"
#include "Maps.hpp"
#include <vector>

using namespace std;

// height sum, bumpiness, clears, holes
const vector<int> weights {-40, -25, 200, -400};


Solver::Input::Input (int g[20][10], int p) {
    grid = Grid(20, vector<Piece_t>(10));
    for (int y=0; y<20; y++)
        for (int x=0; x<10; x++)
            grid[y][x] = static_cast<Piece_t>( g[y][x] );
    piece = static_cast<Piece_t>( p );
};

void Solver::printGrid(Grid* grid) {
    printf("\n");
    for (int y=0; y<20; y++) {
        string str = "";
        for (int x=0; x<10; x++) {
            str += (((*grid)[y][x] != Piece_t::None)? '0' + static_cast<int>((*grid)[y][x])-1 : '.');
            str += ' ';
        }
        str += "\n";
        printf("%s", str.c_str());
    }
}

Grid* Solver::place(Grid& ref, Piece_t piece, int i_x, int r) {
    Grid *grid = new Grid(ref);
    const vector<int> &piece_map = piece_maps[static_cast<int>(piece)-1][r];
    int n = piece == Piece_t::I ? 5 : 3;
    int c_x = i_x - (piece == Piece_t::I ? 2 : 1);
    
    // finds the first conflicting y-pos, stores in c_y
    // Then subtracts by a constant offset to get the center_y
    int c_y = 2;
    bool clear = true;
    while (clear && c_y < 20) {
        for (int y=0; y<n && clear; y++)
            for (int x=0; x<n && clear; x++)
                if (piece_map[y*n +x]) {
                    if (c_x + x < 0 || c_x + x >= 10)
                        return nullptr;
                    if (c_y + y < 0 || c_y + y >= 20) {
                        clear = false;
                        continue;
                    }
                    if ((*grid)[c_y + y][c_x + x] != Piece_t::None)
                        clear = false;
                }
        c_y ++;
    }
    c_y -= (piece == Piece_t::I ? 2 : 1) + 1;
    for (int y=0; y<n; y++)
        for (int x=0; x<n; x++)
            if (piece_map[y*n +x])
                (*grid)[c_y + y][c_x + x] = piece;
    return grid;
}

int Solver::evaluate(const vector<int>* weights, Grid* grid) {
    vector<int> heights (10,0);
    int clears = 0;
    int holes = 0;
    
    // calculate heights, holes, and clears
    for (int y=0; y<20; y++) {
        bool clear = true;
        for (int x=0; x<10; x++) {
            if ((*grid)[y][x] != Piece_t::None && heights[x] == 0)
                heights[x] = 20 - y;
            if (y)
                if ((*grid)[y][x] == Piece_t::None && (*grid)[y-1][x] != Piece_t::None)
                    holes ++;
            if ((*grid)[y][x] == Piece_t::None)
                clear = false;
        }
        if (clear)
            clears ++;
    }
    int heightSum = 0;
    int bumpiness = 0;
    // calculate height sum, bumpiness
    for (int i=0; i<10; i++) {
        heightSum += heights[i];
        if (i)
            bumpiness += abs(heights[i] - heights[i-1]);
    }
    // height sum, bumpiness, clears, holes
    int score = heightSum * (*weights)[0] + bumpiness * (*weights)[1] + clears * (*weights)[2] + holes * (*weights)[3];
    
    Solver::printGrid(grid);
    printf("Evaluated grid above, score:%d \n", score);
    return score;
}

Solver::Output Solver::solve(Solver::Input input) {
    printf("Solver::solve called, piece: %d \n", input.piece);
    printGrid(&input.grid);
    
    Output output = Solver::Output(0,0);
    int best_score = -1e8;
    int paths = 0;
    
    for (int r=0; r<4; r++) {
        for (int x=0; x<10; x++) {
            Grid* grid = Solver::place(input.grid, input.piece, x, r);
            if (grid == nullptr)
                continue;
            
            int score = Solver::evaluate(&weights, grid);
            if (score > best_score) {
                best_score = score;
                output = Solver::Output(x,r);
                output.grid = grid;
            } else {
                delete grid;
            }
            paths++;
        }
    }
    printf("Solver done, after %d paths, produced output x:%d, r:%d \n", paths, output.x, output.r);
    return output;
};
std::string Solver::greet() {
    return "Hello python from c++!";
}
