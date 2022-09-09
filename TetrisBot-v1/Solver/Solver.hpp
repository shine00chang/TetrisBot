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
#include <set>
#include <array>

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
    Garbage,
    Some,
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
typedef std::array<u_int64_t, 4> Grid_min;

const int kWeights = 16;
struct Weights {
    double height = 0;
    double height_H2 = -15;
    double height_Q4 = -50;
    double holes = -70;
    double hole_depth = -15;
    double hole_depth_sq = -4;
    double clear1 = -200;
    double clear2 = -200;
    double clear3 = -200;
    double clear4 = 10000;
    double bumpiness = -2;
    double bumpiness_sq = -4;
    double max_well_depth = 60;
    double well_depth = 20;
    double well_placement[10] = {2, -1.5, 0, 0, 1.5, 1.5, 0, 0, -1.5, 2};
    double combo = 150;
    double b2b_bonus = 50;
    double b2b_break = -100;
    double tspin_single = -100;
    double tspin_double = 4000;
    double tspin_triple = 10000;
    double tspin_completion_sq = 0;
};

struct GridInfo {
    GridInfo (Piece_t _piece, Pos _pos, bool _spun);
    Clear_t clear = Clear_t::None;
    Piece_t piece = Piece_t::None;
    Pos pos = Pos(0,0);
    bool spun = false;
    double score = 0;

    // stats
    int wellPos = -1;
    int wellValue = 0;
    int holes = 0;
    int holeDepthSqSum = 0;
    int bumpiness = 0;
};
struct Input {
    Input (int g[20][10], bool simple = false);
    Grid grid;
};
struct Output {
    Output (int _x, int _r, bool _hold) : x{_x}, r{_r}, hold{_hold}{};
    int x, r;
    int spin = 0;
    bool hold;
    Grid grid;
};
struct Node {
private:
    Grid* grid = nullptr;
    Grid_min* grid_min = nullptr;
    
public:
    Node ();
    Node (const Node* node);
    ~Node ();
    
    
    void generateGridMin();
    Grid* toColorGrid() const;
    Piece_t getGrid (int x, int y) const;
    void setGrid(int x, int y, Piece_t p);
    void setGrid(Grid* ref);
    const Grid_min* getGridMinPtr() const;
    const Grid* getGridPtr() const;
    //const bool addToVisited(std::set<Grid_min>* visited) const;

    std::list<Node*> children;
    Node* parent = nullptr;
    Node* best = nullptr;
    long long id = -1;
    bool explored = false;
    
    std::list<Piece_t>::iterator piece_it;
    Piece_t hold = Piece_t::None;
    GridInfo* gridInfo = nullptr;
    Output* output = nullptr;
    int layer = 0;
};

class Solver {
    // --- Mechanics ---
    static double evaluate(Node* node);
    static void checkClears (Node* node);
    static void processNode (Node* node);
    static std::tuple<Node*, Pos> applySpin(const Node* ref, Piece_t Piece, Pos pos, int r, int nr);
    static std::tuple<Node*, Pos> place (const Node* ref, Piece_t piece, int x, int r);

    // --- Algo ---
    static void Explore (Node* ref, Piece_t piece, void (*treatment)(Node* child) = [](Node* child){return;});
    static void clearTree (Node* node, Node* exception = nullptr);
    
    // --- Helper ---
    static void printGrid (Node* node, bool both=false);
    static void printNode (Node* node, std::string tags="");

public:
    static Output* solve(Input *input, double pTime, bool returnOutput, bool first);
    static void updatePieceStream (int* p, int h, bool first = false);
    static void resetSolver();
    
    // Config (settings)
    static void loadConfigs();
};
#endif /* Solver_hpp */
