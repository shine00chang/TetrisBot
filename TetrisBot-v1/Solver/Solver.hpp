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

typedef std::pair<int,int> Pos;

const int kWeights = 16;
enum class Piece_t : int {
    None,
    J,
    L,
    S,
    Z,
    T,
    I,
    O,
    Garbage
};
extern const std::string pieceName [9];
enum class Clear_t : int {
    None,
    clear1,
    clear2,
    clear3,
    clear4,
    tspin_double,
};

typedef std::vector<std::vector<Piece_t>> Grid;

struct Weights {
    double height = -30;
    double height_H2 = -150;
    double height_Q4 = -511;
    double holes = -400;
    double hole_depth = -50;
    double hole_depth_sq = 5;
    double clear1 = -230;
    double clear2 = -200;
    double clear3 = -160;
    double clear4 = 400;
    double bumpiness = -40;
    double bumpiness_sq = -14;
    double max_well_depth = 50;
    double well_depth = 15;
    double well_placement[10] = {20, -10, 0, 30, 15, 15, 30, 0, -15, 20};
    double combo = 150;
    double b2b_bonus = 52;
    double b2b_break = -100;
    double tspin_double = 600;
    double tspin_completion_sq = 50;
};
struct GridInfo {
    Clear_t clear = Clear_t::None;
    int wellpos = -1;
    int welldepth = 0;
    std::pair<int,int> tspinCoord = std::pair<int,int>(-1,-1);
};
struct Input {
    Input (int **g, int p, int h, double *w = nullptr);
    Grid grid;
    Piece_t piece;
    Piece_t hold = Piece_t::None;
    Weights weights;
};
struct Output {
    Output (int _x, int _r, bool _hold) : x{_x}, r{_r}, hold{_hold}{};
    int x, r;
    int spin = 0;
    bool hold;
    Grid* grid = nullptr;
    int score = 0;
    GridInfo* gridInfo = nullptr;
};


class Solver {

    static std::tuple<Grid*, Pos> place (Grid &ref, Piece_t piece, int x, int r);
    static double evaluate(Grid *grid, GridInfo* gridInfo, Weights &weights);
    static void checkClears (Grid* grid, GridInfo* gridInfo);
    static void processNode (Grid *grid, GridInfo *info, bool isRoot = false);
    static void findBestNode(Grid& ref, Piece_t piece, Weights& weights, Output** output, bool isHold = false);
    static Grid* applySpin(Grid& ref, Piece_t Piece, Pos pos, int r, int nr);
    
    static void printGrid (Grid* grid);
    
public:

    static Output* solve(Input *input);
    static int greet();
};
#endif /* Solver_hpp */
