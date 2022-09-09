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
        self->pieces = new int[6];
        for (int i=0; i<6; i++)
            self->pieces[i] = 0;
    }
    return self;
}
-(void) setGrid: (int)x :(int)y :(int) val {
    self->grid[y][x] = val;
}
-(void) setPieces: (int)i :(const int) val {
    self->pieces[i] = val;
}
-(void) setHold: (const int) val {
    self->hold = val;
}
@end
