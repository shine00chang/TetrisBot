//
//  Maps.hpp
//  TetrisBot-v1
//
//  Created by Shine Chang on 6/21/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#ifndef Maps_hpp
#define Maps_hpp

#include <stdio.h>
#include <vector>

typedef std::vector<std::vector<int>> Map;
typedef std::pair<int,int> Pos;

extern const std::vector<Map> piece_maps;
extern const Map tsd_maps;
extern const Pos kick_table[6][4][5];

#endif /* Maps_hpp */
