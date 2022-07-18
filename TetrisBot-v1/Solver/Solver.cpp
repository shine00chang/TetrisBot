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
#include <list>
#include <chrono>

//#define SOLVER_LOG

using namespace std;

const string pieceName [9] = {
    "None",
    "J",
    "L",
    "S",
    "Z",
    "T",
    "I",
    "O",
    "Garbage"
};
const Weights default_weights = Weights();

// --- Algo ---
const int kCandidateSize = 10;

Node* root;
list<Node*> candidates;
list<Piece_t> piece_stream;
Piece_t rootHold;
int new_pieces = 1;

// --- Logging ---
int nodes_processed = 0;

Input::Input (int **g, double *w, bool simple) {
    grid = Grid(20, vector<Piece_t>(10));
    for (int y=0; y<20; y++)
        for (int x=0; x<10; x++)
            grid[y][x] = static_cast<Piece_t>( g[y][x] );
        
    if (w == nullptr)
        weights = default_weights;
    else {
        if (!simple) {
            weights.height = -w[0];
            weights.height_H2 = -w[1];
            weights.height_Q4 = -w[2];
            weights.holes = -w[3];
            weights.hole_depth = -w[4];
            weights.hole_depth_sq = -w[5];
            weights.clear1 = w[6];
            weights.clear2 = w[7];
            weights.clear3 = w[8];
            weights.clear4 = w[9];
            weights.bumpiness = -w[10];
            weights.bumpiness_sq = -w[11];
            weights.max_well_depth = w[12];
            weights.well_depth = w[13];
            weights.tspin_single = w[14];
            weights.tspin_double = w[15];
            weights.tspin_triple = w[16];
            weights.tspin_completion_sq = w[17];
        } else {
            weights.height = -w[0];
            weights.height_H2 = 0;
            weights.height_Q4 = 0;
            weights.holes = -w[1];
            weights.hole_depth = 0;
            weights.hole_depth_sq = 0;
            weights.clear1 = w[2];
            weights.clear2 = w[2];
            weights.clear3 = w[2];
            weights.clear4 = w[2];
            weights.bumpiness = -w[3];
            weights.bumpiness_sq = 0;
            weights.max_well_depth = 0;
            weights.well_depth = 0;
            weights.tspin_single = 0;
            weights.tspin_double = 0;
            weights.tspin_triple = 0;
            weights.tspin_completion_sq = 0;
        }
    }
};
GridInfo::GridInfo (Piece_t _piece, Pos _pos, bool _spun) {
    piece = _piece;
    pos = _pos;
    spun = _spun;
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

void Solver::processNode(Grid *grid, GridInfo *info, bool isRoot) {
    // Find well
    int wellpos = -1;
    int welldepth = 0;

    info->wellpos = wellpos;
    info->welldepth = welldepth;
    
    if (isRoot) return;
    Solver::checkClears(grid, info);
}

tuple<Grid*, Pos> Solver::place(Grid& ref, Piece_t piece, int i_x, int r) {
    Grid *grid = new Grid(ref);
    const vector<int> &piece_map = piece_maps[int(piece)-1][r];
    int n = piece == Piece_t::I ? 5 : 3;
    int c_x = i_x - (piece == Piece_t::I ? 2 : 1);
    
    // finds the first conflicting y-pos, stores in c_y
    // Then subtracts by a constant offset to get the center_y
    int c_y = 0;
    bool clear = true;
    while (clear && c_y < 20) {
        for (int y=0; y<n && clear; y++)
            for (int x=0; x<n && clear; x++)
                if (piece_map[y*n +x]) {
                    if (c_x + x < 0 || c_x + x >= 10)
                        return make_tuple(nullptr, Pos(0,0));
                    if (c_y + y >= 20) {
                        clear = false;
                        continue;
                    }
                    if ((*grid)[c_y + y][c_x + x] != Piece_t::None)
                        clear = false;
                }
        c_y ++;
    }
    // because of the last "c_y++", the codeblock above sets c_y to the level after the first OVERLAP
    // as such, to get the first CONTACT level we must subtract by two.
    c_y -= 2;
    // however because we never checked if level "-1" has overlaps, we cannot use it.
    if (c_y < 0)
        return make_tuple(nullptr, Pos(0,0));
    
    for (int y=0; y<n; y++)
        for (int x=0; x<n; x++)
            if (piece_map[y*n +x]) {
                if (c_y + y < 0) // if past board limit (game over)
                    return make_tuple(nullptr, Pos(0,0));
                (*grid)[c_y + y][c_x + x] = piece;
            }
    return make_tuple(grid, Pos(c_x, c_y));
}

void Solver::checkClears(Grid* grid, GridInfo* gridInfo) {
    // 3-Corner Check for tspins.
    bool tspin = false;
    if (gridInfo->spun && gridInfo->piece == Piece_t::T) {
        int cnt = 0;
        Pos &pos = gridInfo->pos;
        
        if (pos.first >= 0 && pos.second >= 0 && pos.first < 10 && pos.second < 20)
            cnt += (*grid)[pos.second][pos.first] != Piece_t::None;
        if (pos.first+2 >= 0 && pos.second >= 0 && pos.first+2 < 10 && pos.second < 20)
            cnt += (*grid)[pos.second][pos.first +2] != Piece_t::None;
        if (pos.first >= 0 && pos.second+2 >= 0 && pos.first < 10 && pos.second+2 < 20)
            cnt += (*grid)[pos.second +2][pos.first] != Piece_t::None;
        if (pos.first+2 >= 0 && pos.second+2 >= 0 && pos.first+2 < 10 && pos.second+2 < 20)
            cnt += (*grid)[pos.second +2][pos.first +2] != Piece_t::None;

        if (cnt >= 3)
            tspin = true;
    }
    
    // clear check
    int clears = 0;
    for (int y=19; y>=0; y--) {
        bool clear = true;
        for (int x=0; x<10; x++) {
            if ((*grid)[y][x] == Piece_t::None)
                clear = false;
            if (clears) {
                (*grid)[y+clears][x] = (*grid)[y][x];
                (*grid)[y][x] = Piece_t::None;
            }
        }
        if (clear)
            clears ++;
    }
    gridInfo->clear = static_cast<Clear_t>(clears);

    if (tspin)
        switch (clears) {
            case 1:
                gridInfo->clear = Clear_t::tspin_single;
                break;
            case 2:
                gridInfo->clear = Clear_t::tspin_double;
                break;
            case 3:
                gridInfo->clear = Clear_t::tspin_triple;
                break;
        }
}

double Solver::evaluate (Grid *grid, GridInfo *gridInfo, Weights &weights) {
    
    int maxHeight = -1;
    int holes = 0;
    int heights[10] = {0,0,0,0,0,0,0,0,0,0}; // first contact with filled
    int wellValue = 0;
    int wellDepth = 21;
    int wellPos = -1;
    int cellsCoveringHoles = 0;
    int cellsCoveringHoles_sq = 0;
    
    // gets height && holes
    for (int x=0; x<10; x++) {
        for (int y=0; y<20; y++) {
            // height
            if ((*grid)[y][x] != Piece_t::None && heights[x] == 0)
                heights[x] = 20 - y;
            // holes
            if (y > 0) {
                if ((*grid)[y][x] == Piece_t::None && (*grid)[y-1][x] != Piece_t::None) {
                    int cells = heights[x] - (20-y);
                    cellsCoveringHoles += cells;
                    cellsCoveringHoles_sq += cells * cells;
                    holes++;
                }
            }
        }
        maxHeight = max(maxHeight, heights[x]);
    }
    // get well pos
    for (int x=0; x<10; x++) {
        if (wellDepth > heights[x]) {
            wellDepth = heights[x];
            wellPos = x;
        }
    }

    // gets well value (how many lines it can clear)
    for (int y=19-wellDepth; y>=0; y--) {
        bool full = true;
        for (int x=0; x<10; x++)
            if (x != wellPos && (*grid)[y][x] == Piece_t::None)
                full = false;
        wellValue += full;
        if (not full)
            break;
    }
    wellValue = min(wellValue, 5);
    
    int totalDifference = 0;
    int totalDifference_sq = 0;
    int prev = 0;
    for (int x=1; x<10; x++) {
        int diff = abs(heights[x] - heights[prev]);
        totalDifference += diff;
        totalDifference_sq += diff * diff;
        prev = x;
    }

    // TSPIN
    int tspin_double_completion = 0;
    
    // For each variation, apply map to each 'x' at height[x] & height[x] + 2
    for (int k=0; k<2; k++) {
        const vector<int>& map = tsd_maps[k];
        for (int l=0; l<2; l++) {
            for (int x=0; x<10-2; x++) {
                // because we need to apply it to both heightx & heightx +2 (because of overhang), some ugly numbers appear.
                int y = min (17, (19 - heights[x] + (l? -1 : 1)));
                if (y < 0)
                    continue;
                
                int completion = 0;
                bool possible = true;
                
                for (int i=0; i<3 && possible; i++) {
                    for (int j=0; j<3 && possible; j++) {
                        if ( map[i*3 + j] && (*grid)[y + i][x + j] != Piece_t::None)  // if filled on right spot (+ points)
                            completion ++;
                        if (!map[i*3 + j] && (*grid)[y + i][x + j] != Piece_t::None)  // if filled when not supposed to (fail).
                            possible = false;
                    }
                }
                // make sure the tspin is accessible.
                // given that the spots that are supposed to be empty in the 3x3 are (provided by 'possible'), the heights
                // just need to be less than or equal to 'y' to determine if it is accessible.
                if (possible && heights[x] <= 20-y && heights[x+1] <= 20-y && heights[x+2] <= 20-y)
                    tspin_double_completion = max(tspin_double_completion, completion);
            }
        }
    }
    
    
    double score = 0;
    score += maxHeight * weights.height;
    if (maxHeight >= 10) score += maxHeight * weights.height_H2;
    if (maxHeight >= 15) score += maxHeight * weights.height_Q4;
    score += holes * weights.holes;
    switch (gridInfo->clear) {
        case Clear_t::clear1:
            score += weights.clear1;
            break;
        case Clear_t::clear2:
            score += weights.clear2;
            break;
        case Clear_t::clear3:
            score += weights.clear3;
              break;
        case Clear_t::clear4:
            score += weights.clear4;
            break;
        case Clear_t::tspin_single:
             score += weights.tspin_single;
            break;
        case Clear_t::tspin_double:
            score += weights.tspin_double;
            break;
        case Clear_t::tspin_triple:
            score += weights.tspin_triple;
            break;
        default:
            break;
    }
    score += totalDifference * weights.bumpiness;
    score += totalDifference_sq * weights.bumpiness_sq;
    if (wellDepth == 0) score += wellValue * weights.max_well_depth + weights.well_placement[wellPos];
    else  score += wellValue * weights.well_depth * weights.well_placement[wellPos];
    score += cellsCoveringHoles * weights.hole_depth;
    score += cellsCoveringHoles_sq * weights.hole_depth_sq;
    
    score += tspin_double_completion * tspin_double_completion * weights.tspin_completion_sq;
     
#ifdef SOLVER_LOG
    Solver::printGrid(grid);
    printf("Evaluated grid above, score:%lf \n", score);
#endif
    return score;
}

std::tuple<Grid*, Pos> Solver::applySpin(Grid& ref, Piece_t piece, Pos pos, int r, int nr) {
    // the kick table is generated under
    // the assumption that y axis grows upwards
    
    if (piece == Piece_t::O || piece == Piece_t::I) return make_tuple(nullptr, Pos(0,0));;
    
    const Pos* offset1 = kick_table[int(piece)-1][r];
    const Pos* offset2 = kick_table[int(piece)-1][nr];
    
    Pos kicks[5];
    for (int i=0; i<5; i++) {
        kicks[i] = Pos(
            offset1[i].first - offset2[i].first,
            offset1[i].second - offset2[i].second
        );
    }
    const vector<int> map = piece_maps[int(piece)-1][nr];
    int n = piece == Piece_t::I ? 5 : 3;
    for (int k=0; k<5; k++) {
        Pos npos = Pos(pos.first + kicks[k].first, pos.second - kicks[k].second);
        bool clear = true;
        for (int i=0; i<n; i++)
            for (int j=0; j<n; j++)
                if (map[i*n + j]) {
                    if (npos.second + i < 0 || npos.second + i >= 20 || npos.first + j < 0 || npos.first + j >= 10) {
                        clear = false;
                        continue;
                    }
                    if (ref[npos.second + i][npos.first + j] != Piece_t::None)
                        clear = false;
                }
            
        if (clear) {
            // shift it down to the lowest available coordinate
            Grid* grid = new Grid(ref);
            bool clear = true;
            int k = 0;
            while (clear) {
                k++;
                for (int i=0; i<n; i++)
                    for (int j=0; j<n; j++)
                        if (map[i*n + j])
                            if (npos.second + i + k > 19 || (*grid)[npos.second + i + k][npos.first + j] != Piece_t::None)
                                clear = false;
            }
            npos.second += k-1;
            for (int i=0; i<n; i++)
                for (int j=0; j<n; j++)
                    if (map[i*n + j])
                        (*grid)[npos.second + i][npos.first + j] = piece;
            return make_tuple(grid, npos);
        }
    }
    return make_tuple(nullptr, Pos(0,0));
}

void Solver::Explore (Node* ref, Piece_t piece, Weights& weights, void (*treatment)(Node* child)) {
    for (int r=0; r<4; r++) {
        for (int x=0; x<10; x++) {
            pair<Grid*, Pos> pathes[3];
            pathes[0] = Solver::place(*ref->grid, piece, x, r);
            if (pathes[0].first == nullptr)
                continue;
            
            // NOTE: the pos values returned by 'place' is a coner pos, not center pos.
            pathes[1] = Solver::applySpin(*ref->grid, piece, pathes[0].second, r, (r+1)%4);
            pathes[2] = Solver::applySpin(*ref->grid, piece, pathes[0].second, r, (r+3)%4);

            for (int i=0; i<3; i++) {
                Grid* grid = pathes[i].first;
                Pos pos = pathes[i].second;
                if (grid == nullptr) continue;
                
                // --- Evaluate Child ---
                GridInfo *gridInfo = new GridInfo(piece, pos, i != 0 ? true : false);
                Solver::checkClears(grid, gridInfo);
                gridInfo->score = Solver::evaluate(grid, gridInfo, weights);
                // --- Create corresponding output for child ---
                Output* output = new Output(x,r,false);
                if (i == 1) output->spin =  1;
                if (i == 2) output->spin = -1;
                // --- Construct Child ---
                Node* child = new Node();
                child->parent = ref;
                child->grid = grid;
                child->gridInfo = gridInfo;
                child->output = output;
                child->piece_it = ref->piece_it; child->piece_it++;
                child->hold = ref->hold;
                child->layer = ref->layer +1;
                treatment(child);
                
                // --- Manage Child ---
                nodes_processed ++;
                ref->children.push_back(child);
                // --- Update candidates
                if (candidates.size() < kCandidateSize) {
                    candidates.push_back(child);
                } else {
                    auto it = candidates.end(); it--;
                    bool front = false;
                    while ((*it)->gridInfo->score < child->gridInfo->score) {
                        if (it == candidates.begin()) {
                            front = true;
                            break;
                        }
                        it --;
                    }
                    // if adding to front
                    if (front) {
                        candidates.push_front(child);
                        candidates.pop_back();
                        continue;
                    }
                    it ++;
                    if (it != candidates.end()) {
                        candidates.insert(it, child);
                        candidates.pop_back();
                    }
                }
            }
        }
    }
}

void Solver::clearTree(Node* node, Node* exception) {
    for (Node* child : node->children)
        if (child != exception)
            clearTree(child);
    delete node->grid;
    delete node->gridInfo;
    delete node->output;
}

Output* Solver::solve(Input* input, double pTime, bool returnOutput, bool first) {
    nodes_processed = 0;
    // if first move.
    
    root = new Node();
    root->grid = &input->grid;
    root->piece_it = piece_stream.begin();
    root->hold = rootHold;
    root->gridInfo = new GridInfo(Piece_t::None, Pos(0,0), false);
    candidates.clear();
    
    std::chrono::steady_clock::time_point begin = std::chrono::steady_clock::now();
    do {
        // select node
        Node* node = nullptr;
        if (!candidates.empty()) {
            {
                int node_i = arc4random_uniform((int) candidates.size());
                auto node_it = candidates.begin();
                for (int i=0; i<node_i; i++)
                    node_it ++;
                node = *node_it;
            }
        } else
            node = root;
        
        Solver::Explore(node, *node->piece_it, input->weights);
        if (node->hold != Piece_t::None)
            Solver::Explore(node, node->hold, input->weights, [](Node* child){
                child->output->hold = true;
                child->hold = *child->parent->piece_it;
            });
        else {
            auto piece_it = node->piece_it;
            piece_it ++;
            Solver::Explore(node, *piece_it, input->weights, [](Node* child) {
                child->output->hold = true;
                auto parent_piece_it = child->parent->piece_it;
                child->hold = *parent_piece_it;
                parent_piece_it ++; parent_piece_it ++;
                child->piece_it = parent_piece_it;
            });
        }
    } while (chrono::duration_cast<chrono::microseconds>(chrono::steady_clock::now() - begin).count()/1000000.0 < pTime);
    if (returnOutput) {
        // If game over
        if (candidates.empty()) {
            printf("game over");
            return nullptr;
        }
            
        // Find output's parent
        Node* best = candidates.front();
        while (best->parent != root)
            best = best->parent;
        Output* output = new Output(*best->output);
        
        printGrid(best->grid);
        printf("parent hold: %s \n", pieceName[(int)root->hold].c_str());
        printf("output hold: %s \n", pieceName[(int)best->hold].c_str());
        for (auto it = root->piece_it; it != piece_stream.end(); it++) {
            
            printf("%s ", pieceName[(int)*it].c_str());
            if (it == root->piece_it) printf("<- parent piece_it");
            if (it == best->piece_it) printf("<- output piece_it");
            
            printf("\n");
        }
        printf("Solver done, produced output x:%d, r:%d, hold:%d, spin:%d after %d nodes processed \n",  output->x, output->r, output->hold, output->spin, nodes_processed);
        
        if (best->gridInfo->clear == Clear_t::tspin_double)
            printf("Did tspin double");
        
        if (root->hold == Piece_t::None && output->hold) {
            new_pieces = 2;
            piece_stream.pop_front();
        }
        piece_stream.pop_front();
        // --- Clear Tree ---
        Solver::clearTree(root);
        
        return output;
    } else
        return nullptr;
};


void Solver::updatePieceStream (int* p, int h, bool first) {
    if (first) {
        piece_stream.clear();
        rootHold = Piece_t::None;
        new_pieces = 6;
    }
    for (int i=0; i<new_pieces; i++)
        piece_stream.push_back(static_cast<Piece_t>(p[6-new_pieces + i]));
    new_pieces = 1;
    
    rootHold = static_cast<Piece_t>(h);
}
