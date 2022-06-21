//
//  GameData.m
//  TetrisBot-v1
//
//  Created by Shine Chang on 6/13/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameData.h"

@implementation C_GameData
-(id) init {
    self = [super init];
    return self;
}
-(int) getPiece {
    return self->piece;
}
-(void) setGrid: (int)x :(int)y :(int) val {
    self->grid[y][x] = val;
}
-(void) setPiece: (const int) val {
    self->piece = val;
}
@end
