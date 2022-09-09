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
#include <string.h>
#include <string>
#include <chrono>
#include <cstdio>
#include <iostream>
#include <fstream>
#include <stdio.h>
#include <array>
#include <map>

#import <Foundation/Foundation.h>


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
const int kCandidateSize = 30;
bool useColorGrid = false;

Weights weights;

Node* root;
Node* best;
list<Node*> candidates;
list<Piece_t> piece_stream;
set<Grid_min> visitedGrids;
Piece_t rootHold;
int layer = 0;

std::set<long long> NodeIdPool;
long long NodeIdMax = 1;

// --- Logging ---
const char* kLogFilePath = "/Users/shinechang/Documents/CS/CS-dev/TetrisBot/Logs/log1.txt";
const char* kConfigFilePath = "./config.txt";
ofstream fs(kLogFilePath, fstream::out);
const int kLogBufferSize = 1000;
char logBuffer[kLogBufferSize * 2];
int nodes_processed = 0;
double avg_explore_time = -1;
bool should_log = false;

void Solver::loadConfigs () {
    
    map<string, double> weightsMap;
    map<string, string> logMap;
    ifstream config_ifs;
    config_ifs.open(kConfigFilePath);

    // If file exists, read
    if (config_ifs) {
        string s;
        getline(config_ifs, s);
        
        while (!s.empty()) {
            if (s.compare("log_config_start")) {
                // -- Read Log configs
                for (;s.compare("log_config_end"); getline(config_ifs, s)) {
                    if (s.substr(0,2).compare("//") == 0) continue;
                    auto pos = s.find(": ");
                    string key = s.substr(0, pos);

                    if (pos == string::npos) {
                        string value = s.substr(pos + 2);
                        logMap[key] = value;
                    } else
                        logMap[key] = "";
                }
            }
            if (s.compare("weights_start")) {
                // -- Read Weights configs
                for (;s.compare("weights_end"); getline(config_ifs, s)) {
                    auto pos = s.find(": ");
                    string key = s.substr(0, pos);
                    string value = s.substr(pos + 2);
                    
                    weightsMap[key] = stod(value);
                }
            }
        }
    }
    // -- Set log configs --
    should_log = logMap.count("should_log");
    
    // -- Set weights --
    weights = default_weights;
    if (weightsMap.count("height")) weights.height = weightsMap["height"];
    if (weightsMap.count("height_H2")) weights.height_H2 = weightsMap["height_H2"];
    if (weightsMap.count("height_Q2")) weights.height_Q4 = weightsMap["height_Q4"];
    if (weightsMap.count("holes")) weights.holes = weightsMap["holes"];
    if (weightsMap.count("hole_depth")) weights.hole_depth = weightsMap["hole_depth"];
    if (weightsMap.count("hole_depth_sq")) weights.hole_depth_sq = weightsMap["hole_depth_sq"];
    if (weightsMap.count("clear1")) weights.clear1 = weightsMap["clear1"];
    if (weightsMap.count("clear2")) weights.clear2 = weightsMap["clear2"];
    if (weightsMap.count("clear3")) weights.clear3 = weightsMap["clear3"];
    if (weightsMap.count("clear4")) weights.clear4 = weightsMap["clear4"];
    if (weightsMap.count("bumpiness")) weights.bumpiness = weightsMap["bumpiness"];
    if (weightsMap.count("bumpiness_sq")) weights.bumpiness_sq = weightsMap["bumpiness_sq"];
    if (weightsMap.count("max_well_depth")) weights.max_well_depth = weightsMap["max_well_depth"];
    if (weightsMap.count("well_depth")) weights.well_depth = weightsMap["well_depth"];
    if (weightsMap.count("tspin_single")) weights.tspin_single = weightsMap["tspin_single"];
    if (weightsMap.count("tspin_double")) weights.tspin_double = weightsMap["tspin_double"];
    if (weightsMap.count("tspin_triple")) weights.tspin_triple = weightsMap["tspin_triple"];
    if (weightsMap.count("tspin_completion_sq")) weights.tspin_completion_sq = weightsMap["tspin_completion_sq"];
}

void Solver::resetSolver() {
    fs.close();
    layer = 0;
    memset(logBuffer, 0, sizeof(logBuffer));
    fs.open(kLogFilePath, fstream::out | fstream::trunc);
}

bool operator<(const Grid_min& a, const Grid_min& b) {
    for (int i=0; i<4; i++)
        if (a[i] != b[i])
            return a[i] < b[i];
    return false;
}

template<typename ... Args>
void Log (const char* format, Args ... args) {
    if (!should_log) return;
        
    if (strlen(logBuffer) + strlen(format) > kLogBufferSize) {
        fs << logBuffer;
        memset(logBuffer, 0, sizeof(logBuffer));
    }
    sprintf(logBuffer + strlen(logBuffer), format, args...);
    return;
}

template<typename ... Args>
void LogBoth (const char* format, Args ... args) {
    if (!should_log) return;
    
    Log(format, args...);
    
    char fmt[strlen(format)];
    strcpy(fmt, format);
    if (fmt[strlen(fmt)-1] == '\n')
        fmt[strlen(fmt)-1] = ' ';
    NSLog(@(format), args...);
}

void emptyLogBuffer () {
    fs << logBuffer;
    memset(logBuffer, 0, sizeof(logBuffer));
}


Input::Input (int g[20][10], bool simple) {
    grid = Grid(20, vector<Piece_t>(10));
    for (int y=0; y<20; y++)
        for (int x=0; x<10; x++) 
            grid  [y][x] = static_cast<Piece_t>( g[y][x] );
};
GridInfo::GridInfo (Piece_t _piece, Pos _pos, bool _spun) {
    piece = _piece;
    pos = _pos;
    spun = _spun;
};
Node::Node() {
    // Assign id (for analysis)
    //if (NodeIdPool.empty())
        id = NodeIdMax ++;
    /*else {
        id = *NodeIdPool.begin();
        NodeIdPool.erase(NodeIdPool.begin());
    }*/
    
    if (useColorGrid) {
        (*grid).resize(20);
        for (int y=0; y<20; y++)
            (*grid)[y] = vector<Piece_t>(10, Piece_t::None);
    }
    grid_min = new array<u_int64_t, 4>();
    grid_min->fill(0ULL);
};
Node::Node(const Node* node) {
    // Assign id (for analysis)
    //if (NodeIdPool.empty())
        id = NodeIdMax ++;
    /*else {
        id = *NodeIdPool.begin();
        NodeIdPool.erase(NodeIdPool.begin());
    }*/
    
    // construct grids
    if (useColorGrid)
        grid = new Grid(*node->grid);
    
    grid_min = new Grid_min(*node->grid_min);
};
Node::~Node() {
    if (grid != nullptr)
        delete grid;
    delete grid_min;
    delete gridInfo;
    delete output;
    
    NodeIdPool.insert(id);
};
void Node::generateGridMin() {
    for (int y=0; y<20; y++)
        for (int x=0; x<10; x++)
            setGrid(x, y, (*grid)[y][x]);
};
Piece_t Node::getGrid(int x, int y) const {
    if (useColorGrid) {
        return (*grid)[y][x];
    } else {
        int index = y * 10 + x;
        int arrIndex = index / 64;
        int i = index % 64;
        bool b = (*grid_min)[arrIndex] & (1ULL << i);
        return (b ? Piece_t::Some : Piece_t::None);
    }
}
void Node::setGrid(int x, int y, Piece_t b) {
    int index = y * 10 + x;
    int arrIndex = index / 64;
    int i = index % 64;
    if (b != Piece_t::None)
        (*grid_min)[arrIndex] |= (1ULL << i);
    else
        (*grid_min)[arrIndex] &= ~(1ULL << i);
    
    if (useColorGrid)
        (*grid)[y][x] = b;
}
void Node::setGrid(Grid* ref) {
    grid = ref;
    generateGridMin();
}
Grid* Node::toColorGrid() const {
    Grid* _grid = new Grid(20);
    for (int y=0; y<20; y++)
        (*_grid)[y] = vector<Piece_t>(10, Piece_t::None);
    for (int y=0; y<20; y++)
        for (int x=0; x<10; x++)
            (*_grid)[y][x] = getGrid(x,y);
    return _grid;
}
const Grid_min* Node::getGridMinPtr() const {
    return grid_min;
}
const Grid* Node::getGridPtr() const {
    return grid;
}
/*const bool Node::addToVisited(set<Grid_min>* visited) const {
    return visited->emplace(move(grid_min)).second;
}*/

void Solver::printGrid(Node* node, bool both) {
    for (int y=0; y<20; y++) {
        string str = "";
        for (int x=0; x<10; x++) {
            if (useColorGrid)
                str += ((node->getGrid(x, y) != Piece_t::None) ? '0' + static_cast<int>(node->getGrid(x, y))-1 : '.');
            else
                str += ((node->getGrid(x, y) != Piece_t::None) ? '1' : '.');
            str += ' ';
        }
        if (both)
            LogBoth("LOG-%s\n", str.c_str());
        else
            Log("LOG-%s\n", str.c_str());
    }
}
void Solver::printNode(Node* node, string tags) {
    Log("LOG-node_start\n");
    Log("LOG-tags%s\n", tags.c_str());
    Log("LOG-id %lld\n", node->id);
    
    // Log stats:
    Log("LOG-stats_start\n");
    
    Log("LOG-score %f\n", node->gridInfo->score);
    Log("LOG-wellpos %d\n", node->gridInfo->wellPos);
    Log("LOG-welldepth %d\n", node->gridInfo->wellValue);
    Log("LOG-holes %d\n", node->gridInfo->holes);
    Log("LOG-holeDepthSqSum %d\n", node->gridInfo->holeDepthSqSum);
    Log("LOG-bumpiness %d\n", node->gridInfo->bumpiness);
    
    Log("LOG-stats_end\n");
    // Log grid:
    printGrid(node);
}

void Solver::processNode(Node* node) {
    // any preprocessing that may need to be done
    Solver::checkClears(node);
}

tuple<Node*, Pos> Solver::place(const Node* ref_node, Piece_t piece, int i_x, int r) {
    Node* node = new Node(ref_node);
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
                    if (node->getGrid(c_x+x, c_y+y) != Piece_t::None)
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
                node->setGrid(c_x+x, c_y+y, piece);
            }
    return make_tuple(node, Pos(c_x, c_y));
}

void Solver::checkClears(Node* node) {
    // 3-Corner Check for tspins.
    bool tspin = false;
    if (node->gridInfo->spun && node->gridInfo->piece == Piece_t::T) {
        int cnt = 0;
        Pos &pos = node->gridInfo->pos;
        
        if (pos.first >= 0 && pos.second >= 0 && pos.first < 10 && pos.second < 20)
            cnt += node->getGrid(pos.first  ,pos.second  ) != Piece_t::None;
        if (pos.first+2 >= 0 && pos.second >= 0 && pos.first+2 < 10 && pos.second < 20)
            cnt += node->getGrid(pos.first+2,pos.second  ) != Piece_t::None;
        if (pos.first >= 0 && pos.second+2 >= 0 && pos.first < 10 && pos.second+2 < 20)
            cnt += node->getGrid(pos.first  ,pos.second+2) != Piece_t::None;
        if (pos.first+2 >= 0 && pos.second+2 >= 0 && pos.first+2 < 10 && pos.second+2 < 20)
            cnt += node->getGrid(pos.first+2,pos.second+2) != Piece_t::None;

        if (cnt >= 3)
            tspin = true;
    }
    
    // clear check
    int clears = 0;
    for (int y=19; y>=0; y--) {
        bool clear = true;
        for (int x=0; x<10; x++) {
            if (node->getGrid(x,y) == Piece_t::None)
                clear = false;
            if (clears) {
                node->setGrid(x, y+clears, node->getGrid(x,y));
                node->setGrid(x, y, Piece_t::None);
            }
        }
        if (clear)
            clears ++;
    }
    node->gridInfo->clear = static_cast<Clear_t>(clears);

    if (tspin)
        switch (clears) {
            case 1:
                node->gridInfo->clear = Clear_t::tspin_single;
                break;
            case 2:
                node->gridInfo->clear = Clear_t::tspin_double;
                break;
            case 3:
                node->gridInfo->clear = Clear_t::tspin_triple;
                break;
        }
}

double Solver::evaluate(Node* node) {
    
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
            if (node->getGrid(x,y) != Piece_t::None && heights[x] == 0)
                heights[x] = 20 - y;
            // holes
            if (y > 0) {
                if (node->getGrid(x,y) == Piece_t::None && node->getGrid(x,y-1) != Piece_t::None) {
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
            if (x != wellPos && node->getGrid(x,y) == Piece_t::None)
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
                        if ( map[i*3 + j] && node->getGrid(x + j, y + i) != Piece_t::None)  // if filled on right spot (+ points)
                            completion ++;
                        if (!map[i*3 + j] && node->getGrid(x + j, y + i) != Piece_t::None)  // if filled when not supposed to (fail).
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
    // Assign stats to gridinfo
    node->gridInfo->wellPos = wellPos;
    node->gridInfo->wellValue = wellValue;
    node->gridInfo->bumpiness = totalDifference;
    node->gridInfo->holes = holes;
    node->gridInfo->holeDepthSqSum = cellsCoveringHoles_sq;

    // score calculation
    double score = 0;
    score += maxHeight * weights.height;
    if (maxHeight >= 10) score += maxHeight * weights.height_H2;
    if (maxHeight >= 15) score += maxHeight * weights.height_Q4;
    score += holes * weights.holes;
    switch (node->gridInfo->clear) {
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
    if (wellDepth == 0) score += wellValue * weights.max_well_depth * weights.well_placement[wellPos];
    else  score += wellValue * weights.well_depth * weights.well_placement[wellPos];
    score += cellsCoveringHoles * weights.hole_depth;
    score += cellsCoveringHoles_sq * weights.hole_depth_sq;
    
    score += tspin_double_completion * tspin_double_completion * weights.tspin_completion_sq;

    
    return score;
}

std::tuple<Node*, Pos> Solver::applySpin(const Node* ref, Piece_t piece, Pos pos, int r, int nr) {
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
                    if (ref->getGrid(npos.first + j, npos.second + i) != Piece_t::None)
                        clear = false;
                }
            
        if (clear) {
            // shift it down to the lowest available coordinate
            Node* node = new Node(ref);
            bool clear = true;
            int k = 0;
            while (clear) {
                k++;
                for (int i=0; i<n; i++)
                    for (int j=0; j<n; j++)
                        if (map[i*n + j])
                            if (npos.second + i + k > 19 || node->getGrid(npos.first + j, npos.second + i + k) != Piece_t::None)
                                clear = false;
            }
            npos.second += k-1;
            for (int i=0; i<n; i++)
                for (int j=0; j<n; j++)
                    if (map[i*n + j])
                        node->setGrid(npos.first + j, npos.second + i, piece);
            return make_tuple(node, npos);
        }
    }
    return make_tuple(nullptr, Pos(0,0));
}

void Solver::Explore (Node* ref, Piece_t piece, void (*treatment)(Node* child)) {
    int rotations = 4;
    //if (piece == Piece_t::I) rotations = 2;
    if (piece == Piece_t::O) rotations = 1;
    
    for (int r=0; r<rotations; r++) {
        for (int x=0; x<10; x++) {
            pair<Node*, Pos> pathes[3];
            pathes[0] = Solver::place(ref, piece, x, r);
            if (pathes[0].first == nullptr)
                continue;
            
            // NOTE: the pos values returned by 'place' is a corner pos, not center pos.
            pathes[1] = Solver::applySpin(ref, piece, pathes[0].second, r, (r+1)%4);
            pathes[2] = Solver::applySpin(ref, piece, pathes[0].second, r, (r+3)%4);

            for (int i=0; i<3; i++) {
                Node* child = pathes[i].first;
                Pos pos = pathes[i].second;
                if (child == nullptr) continue;
                
                // --- Check if reoccurance ---
                if (visitedGrids.emplace(move(*child->getGridMinPtr())).second == false)
                    continue;
                
                
                // --- Evaluate Child ---
                child->gridInfo = new GridInfo(piece, pos, i != 0 ? true : false);
                Solver::checkClears(child);
                child->gridInfo->score = Solver::evaluate(child);
                // --- Create corresponding output for child ---
                Output* output = new Output(x,r,false);
                if (i == 1) output->spin =  1;
                if (i == 2) output->spin = -1;
                // --- Construct Child ---
                child->parent = ref;
                child->output = output;
                child->piece_it = next(ref->piece_it);
                child->hold = ref->hold;
                child->layer = ref->layer +1;
                treatment(child);
                
                // --- Manage Child ---
                nodes_processed ++;
                ref->children.push_back(child);
                if (ref->best == nullptr || ref->best->gridInfo->score < child->gridInfo->score)
                    ref->best = child;
                // --- Update best ---
                if (best == nullptr || child->gridInfo->score > best->gridInfo->score)
                    best = child;

                // --- Update candidates ---
                if (child->piece_it == prev(piece_stream.end()))
                    continue;
                if (candidates.empty())
                    candidates.push_back(child);
                else {
                    auto it = prev(candidates.end());
                    bool front = false;
                    while ((*it)->gridInfo->score < child->gridInfo->score) {
                        if (it == candidates.begin()) {
                            front = true;
                            break;
                        }
                        advance(it, -1);
                    }
                    // if adding to front
                    if (front)
                        candidates.push_front(child);
                    else {
                        advance(it, 1);
                        candidates.insert(it, child);
                    }
                    if (candidates.size() > kCandidateSize)
                        candidates.pop_back();
                }
            }
        }
    }
}

void Solver::clearTree(Node* node, Node* exception) {
    for (Node* child : node->children)
        if (child != exception)
            clearTree(child);
    delete node;
}

Output* Solver::solve(Input* input, double pTime, bool returnOutput, bool first) {
    // open & reset log
    nodes_processed = 0;
    Log("LOG-solver_start %d\n", layer);
    
    Node* root = new Node();
    root->setGrid(&input->grid);
    root->generateGridMin();
    root->piece_it = piece_stream.begin();
    root->hold = rootHold;
    root->gridInfo = new GridInfo(Piece_t::None, Pos(0,0), false);
    root->layer = ++layer;
    root->id = 0;
    
    // Print out root node for analyzer
    printNode(root, " root");
    
    double time_elapsed = 0;
    int explores = 0;
    do {
        std::chrono::steady_clock::time_point explore_start_time = std::chrono::steady_clock::now();
        // select node
        Node* node = nullptr;
        if (!candidates.empty()) {
            int node_i = arc4random_uniform((int) candidates.size());
            auto node_it = next(candidates.begin(), node_i);
            node = *node_it;
            candidates.erase(node_it);
        } else
            node = root;
    
        Solver::Explore(node, *node->piece_it);
        if (node->hold != Piece_t::None)
            Solver::Explore(node, node->hold, [](Node* child){
                child->output->hold = true;
                child->hold = *child->parent->piece_it;
            });
        else {
            auto piece_it = node->piece_it;
            piece_it ++;
            Solver::Explore(node, *piece_it, [](Node* child) {
                child->output->hold = true;
                auto parent_piece_it = child->parent->piece_it;
                child->hold = *parent_piece_it;
                child->piece_it = next(parent_piece_it, 2);
            });
        }
        // Logging explored children
        Log("LOG-children_of %lld %lu\n", node->id, node->children.size());
        for(Node* child : node->children) {
            string tags = "";
            if (child == node->best)
                tags += " best_child_tag";
            printNode(child, tags);
        }
        explores ++;
        double explore_time = chrono::duration_cast<chrono::microseconds>(chrono::steady_clock::now() - explore_start_time).count() / 1000000.0;
        time_elapsed += explore_time;
        if (avg_explore_time == -1) avg_explore_time = explore_time;
        avg_explore_time = (avg_explore_time + explore_time) / 2.0;
        
        LogBoth("Explore time: %lf, average: %lf\n", explore_time, avg_explore_time);
    } while (time_elapsed < pTime);
    LogBoth("LOG-solver_end explores %d processed %d\n", explores, nodes_processed);
    emptyLogBuffer();
    
    if (returnOutput) {
        // If game over
        if (best == nullptr) {
            Log("LOG-Game_Over\n");
            return nullptr;
        }
        
        // Find output's parent
        Node* nextNode = best;
        while (nextNode->parent != root)
            nextNode = nextNode->parent;
        Output* output = new Output(*nextNode->output);
        output->grid = *(useColorGrid ? best->getGridPtr() : best->toColorGrid());
        
        Log("LOG-best_future_grid\n");
        printGrid(best, true);
        LogBoth("LOG-best_move_grid\n");
        printGrid(nextNode);
        LogBoth("LOG-parent_hold: %s\n", pieceName[(int)root->hold].c_str());
        LogBoth("LOG-output_hold: %s\n", pieceName[(int)nextNode->hold].c_str());
        for (auto it = root->piece_it; it != piece_stream.end(); it++) {
            
            LogBoth("LOG-%s \n", pieceName[(int)*it].c_str());
            if (it == root->piece_it) LogBoth("LOG-<- parent piece_it\n");
            if (it == nextNode->piece_it)  LogBoth("LOG-<- output piece_it\n");
        }
        LogBoth("LOG-Solver done, produced output x:%d, r:%d, hold:%d, spin:%d\n",  output->x, output->r, output->hold, output->spin);
        
        if (best->gridInfo->clear == Clear_t::tspin_double)
            LogBoth("LOG-Did tspin double\n");
        
        piece_stream.pop_front();
        if (root->hold == Piece_t::None && output->hold)
            piece_stream.pop_front();
    
        // --- Empty Buffer ---
        emptyLogBuffer();
        
        // --- Clear Tree ---
        candidates.clear();
        best = nullptr;
        NodeIdPool.clear();
        NodeIdMax = 1;
        Solver::clearTree(root);
        visitedGrids.clear();
        
        return output;
    } else
        return nullptr;
};


void Solver::updatePieceStream (int* p, int h, bool first) {
    if (first) {
        piece_stream.clear();
        rootHold = Piece_t::None;
    }
    auto it = piece_stream.begin();
    for (int i=0; i<6; i++) {
        if (it != piece_stream.end()) {
            (*it) = static_cast<Piece_t>(p[i]);
            it ++;
        } else
            piece_stream.push_back(static_cast<Piece_t>(p[i]));
    }
    rootHold = static_cast<Piece_t>(h);
}
