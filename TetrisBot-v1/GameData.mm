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
    if (self) {
        self->grid = new int* [20];
        for (int i=0; i<20; i++)
            grid[i] = new int[10];
    }
    return self;
}
-(void) dealloc {
    delete grid;
}
-(void) setGrid: (int)x :(int)y :(int) val {
    self->grid[y][x] = val;
}
-(void) setPiece: (const int) val {
    self->piece = val;
}
-(void) setHold: (const int) val {
    self->hold = val;
}
-(void) setWeight: (int)i val:(double)val {
    self->weights[i] = val;
}
@end
