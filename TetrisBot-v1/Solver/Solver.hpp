//
//  Solver.hpp
//  TetrisBot-v1
//
//  Created by Shine Chang on 6/13/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#ifndef Solver_hpp
#define Solver_hpp

#include <stdio.h>
#include <vector>

enum class Piece_t : int {
    J,
    L,
    S,
    Z,
    T,
    I,
    O,
    None
};
typedef std::vector<std::vector<Piece_t>> Grid;

class Solver {
public:
    class Input {
    public:
        Input (int g[20][10], int p);
        Grid grid;
        Piece_t piece;
    };
    
    class Output {
    public:
        Output (int _x, int _r) : x{_x}, r{_r} {};
        int x, r;
    };

    static Output solve(Input input);
};
#endif /* Solver_hpp */
