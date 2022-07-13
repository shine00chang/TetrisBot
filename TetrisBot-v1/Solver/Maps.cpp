//
//  Maps.cpp
//  TetrisBot-v1
//
//  Created by Shine Chang on 6/21/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#include "Maps.hpp"

const Map mapJ = {
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
const Map mapL = {
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
const Map mapS = {
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
const Map mapZ = {
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
const Map mapT = {
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
const Map mapI = {
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
const Map mapO = {
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

const std::vector<Map> piece_maps {
    mapJ,
    mapL,
    mapS,
    mapZ,
    mapT,
    mapI,
    mapO,
};



const Map tsd_maps = {
    std::vector<int>{
        1,0,0,
        0,0,0,
        1,0,1,
    },
    std::vector<int>{
        0,0,1,
        0,0,0,
        1,0,1,
    }
};

// SRS kick table NOTE: no O's
const Pos kick_table [6][4][5] = {
    { // J L S Z T
        {
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0)
        },
        {
            Pos( 0, 0),
            Pos( 1, 0),
            Pos( 1,-1),
            Pos( 0, 2),
            Pos( 1, 2)
        },
        {
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0)
        },
        {
            Pos( 0, 0),
            Pos(-1, 0),
            Pos(-1,-1),
            Pos( 0, 2),
            Pos(-1, 2)
        },
    },
    { // J L S Z T
        {
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0)
        },
        {
            Pos( 0, 0),
            Pos( 1, 0),
            Pos( 1,-1),
            Pos( 0, 2),
            Pos( 1, 2)
        },
        {
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0)
        },
        {
            Pos( 0, 0),
            Pos(-1, 0),
            Pos(-1,-1),
            Pos( 0, 2),
            Pos(-1, 2)
        },
    },
    { // J L S Z T
        {
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0)
        },
        {
            Pos( 0, 0),
            Pos( 1, 0),
            Pos( 1,-1),
            Pos( 0, 2),
            Pos( 1, 2)
        },
        {
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0)
        },
        {
            Pos( 0, 0),
            Pos(-1, 0),
            Pos(-1,-1),
            Pos( 0, 2),
            Pos(-1, 2)
        },
    },
    { // J L S Z T
        {
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0)
        },
        {
            Pos( 0, 0),
            Pos( 1, 0),
            Pos( 1,-1),
            Pos( 0, 2),
            Pos( 1, 2)
        },
        {
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0)
        },
        {
            Pos( 0, 0),
            Pos(-1, 0),
            Pos(-1,-1),
            Pos( 0, 2),
            Pos(-1, 2)
        },
    },
    { // J L S Z T
        {
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0)
        },
        {
            Pos( 0, 0),
            Pos( 1, 0),
            Pos( 1,-1),
            Pos( 0, 2),
            Pos( 1, 2)
        },
        {
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 0)
        },
        {
            Pos( 0, 0),
            Pos(-1, 0),
            Pos(-1,-1),
            Pos( 0, 2),
            Pos(-1, 2)
        },
    },
    { // I
        {
            Pos( 0, 0),
            Pos(-1, 0),
            Pos( 2, 0),
            Pos(-1, 0),
            Pos( 2, 0)
        },
        {
            Pos(-1, 0),
            Pos( 0, 0),
            Pos( 0, 0),
            Pos( 0, 1),
            Pos( 0,-2)
        },
        {
            Pos(-1, 1),
            Pos( 1, 1),
            Pos(-2, 1),
            Pos( 1, 0),
            Pos(-2, 0),
        },
        {
            Pos( 0, 1),
            Pos( 0, 1),
            Pos( 0, 1),
            Pos( 0,-1),
            Pos( 0, 2),
        },
    },
};
