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
#include <list>

extern const std::string pieceName [9];
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
enum class Clear_t : int {
    None,
    clear1,
    clear2,
    clear3,
    clear4,
    tspin_single,
    tspin_double,
    tspin_triple,
};

typedef std::pair<int,int> Pos;
typedef std::vector<std::vector<Piece_t>> Grid;

const int kWeights = 16;
struct Weights {
    double height = 0;
    double height_H2 = -150;
    double height_Q4 = -511;
    double holes = -400;
    double hole_depth = -50;
    double hole_depth_sq = 20;
    double clear1 = -230;
    double clear2 = -200;
    double clear3 = -160;
    double clear4 = 4000;
    double bumpiness = -10;
    double bumpiness_sq = -20;
    double max_well_depth = 400;
    double well_depth = 150;
    double well_placement[10] = {2, -1, 0, 3, 1.5, 1.5, 3, 0, -1.5, 2};
    double combo = 150;
    double b2b_bonus = 52;
    double b2b_break = -100;
    double tspin_single = -100;
    double tspin_double = 4000;
    double tspin_triple = 10000;
    double tspin_completion_sq = 50;
};

struct GridInfo {
    GridInfo (Piece_t _piece, Pos _pos, bool _spun);
    Clear_t clear = Clear_t::None;
    Piece_t piece = Piece_t::None;
    Pos pos = Pos(0,0);
    bool spun = false;
    double score = 0;

    int wellpos = -1;
    int welldepth = 0;
};
struct Input {
    Input (int g[20][10], double *w = nullptr, bool simple = false);
    Grid grid;
    Weights weights;
};
struct Output {
    Output (int _x, int _r, bool _hold) : x{_x}, r{_r}, hold{_hold}{};
    int x, r;
    int spin = 0;
    bool hold;
    Grid grid;
};
struct Node {
    std::list<Node*> children;
    Node* parent;
    bool explored = false;
    
    Grid* grid;
    std::list<Piece_t>::iterator piece_it;
    Piece_t hold = Piece_t::None;
    GridInfo* gridInfo;
    Output* output;
    int layer = 0;
};

class Solver {
    // --- Mechanics ---
    static double evaluate(Grid *grid, GridInfo* gridInfo, Weights &weights);
    static void checkClears (Grid* grid, GridInfo* gridInfo);
    static void processNode (Grid *grid, GridInfo *info, bool isRoot = false);
    static std::tuple<Grid*, Pos> applySpin(Grid& ref, Piece_t Piece, Pos pos, int r, int nr);
    static std::tuple<Grid*, Pos> place (Grid &ref, Piece_t piece, int x, int r);

    // --- Algo ---
    static void Explore (Node* ref, Piece_t piece, Weights& weights, void (*treatment)(Node* child) = [](Node* child){return;});
    static void clearTree (Node* node, Node* exception = nullptr);
    
    // --- Helper ---
    static void printGrid (Grid* grid);
    
public:
    static Output* solve(Input *input, double pTime, bool returnOutput, bool first);
    static void updatePieceStream (int* p, int h, bool first = false);

    static int greet();
};
#endif /* Solver_hpp */
