//
//  Maps.cpp
//  TetrisBot-v1
//
//  Created by Shine Chang on 6/21/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#include "Maps.hpp"

const Piece_map mapJ = {
std::vector<int>{
    // origin
    1,0,0,
    1,1,1,
    0,0,0,
},
std::vector<int>{
    // right
    0,1,1,
    0,1,0,
    0,1,0,
},
std::vector<int>{
    // 2
    0,0,0,
    1,1,1,
    0,0,1,
},
std::vector<int>{
    // left
    0,1,0,
    0,1,0,
    1,1,0
}
};
const Piece_map mapL = {
std::vector<int>{
    // origin
    0,0,1,
    1,1,1,
    0,0,0,
},
std::vector<int>{
    // right
    0,1,0,
    0,1,0,
    0,1,1,
},
std::vector<int>{
    // 2
    0,0,0,
    1,1,1,
    1,0,0,
},
std::vector<int>{
    // left
    1,1,0,
    0,1,0,
    0,1,0
}
};
const Piece_map mapS = {
std::vector<int>{
    0,1,1,
    1,1,0,
    0,0,0,
},
std::vector<int>{
    0,1,0,
    0,1,1,
    0,0,1,
},
std::vector<int>{
    0,0,0,
    0,1,1,
    1,1,0,
},
std::vector<int>{
    1,0,0,
    1,1,0,
    0,1,0
}
};
const Piece_map mapZ = {
std::vector<int>{
    1,1,0,
    0,1,1,
    0,0,0,
},
std::vector<int>{
    0,0,1,
    0,1,1,
    0,1,0,
},
std::vector<int>{
    0,0,0,
    1,1,0,
    0,1,1,
},
std::vector<int>{
    0,1,0,
    1,1,0,
    1,0,0
}
};
const Piece_map mapT = {
std::vector<int>{
    0,1,0,
    1,1,1,
    0,0,0,
},
std::vector<int>{
    0,1,0,
    0,1,1,
    0,1,0,
},
std::vector<int>{
    0,0,0,
    1,1,1,
    0,1,0,
},
std::vector<int>{
    0,1,0,
    1,1,0,
    0,1,0
}
};
const Piece_map mapI = {
std::vector<int>{
    0,0,0,0,0,
    0,0,0,0,0,
    0,1,1,1,1,
    0,0,0,0,0,
    0,0,0,0,0,
},
std::vector<int>{
    0,0,0,0,0,
    0,0,0,1,0,
    0,0,0,1,0,
    0,0,0,1,0,
    0,0,0,1,0,
},
std::vector<int>{
    0,0,0,0,0,
    0,0,0,0,0,
    0,0,0,0,0,
    0,1,1,1,1,
    0,0,0,0,0,
},
std::vector<int>{
    0,0,0,0,0,
    0,0,1,0,0,
    0,0,1,0,0,
    0,0,1,0,0,
    0,0,1,0,0,
}
};
const Piece_map mapO = {
    std::vector<int>{
    0,1,1,
    0,1,1,
    0,0,0,
    },
    std::vector<int>{
    0,0,0,
    0,1,1,
    0,1,1,
    },
    std::vector<int>{
    0,0,0,
    1,1,0,
    1,1,0,
    },
    std::vector<int>{
    1,1,0,
    1,1,0,
    0,0,0
    }
};

const std::vector<Piece_map> piece_maps {
    mapJ,
    mapL,
    mapS,
    mapZ,
    mapT,
    mapI,
    mapO,
};
