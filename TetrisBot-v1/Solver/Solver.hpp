//
//  Solver.hpp
//  TetrisBot-v1
//
//  Created by Shine Chang on 6/13/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#ifndef Solver_hpp
#define Solver_hpp

#include <string>
#include <vector>

enum class Piece_t : int {
    None,
    L,
    J,
    S,
    Z,
    T,
    I,
    O,
};
typedef std::vector<std::vector<Piece_t>> Grid;

class Solver {
    static Grid* place (Grid &ref, Piece_t piece, int x, int r);
    static int evaluate (const std::vector<int> *weights, Grid *grid);
    static void printGrid (Grid* grid);
    
public:
    struct Input {
        Input (int g[20][10], int p);
        Grid grid;
        Piece_t piece;
    };
    
    struct Output {
        Output (int _x, int _r) : x{_x}, r{_r} {};
        int x, r;
        Grid* grid = nullptr;
    };

    static Output solve(Input input);
    static std::string greet();
};
#endif /* Solver_hpp */
