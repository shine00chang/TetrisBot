//
//  SolverOutput.m
//  TetrisBot-v1
//
//  Created by Shine Chang on 6/13/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "SolverOutput.h"

@implementation C_SolverOutput : NSObject
-(id) init: (int)x r:(int)r {
    self = [super init];
    self->x = x;
    self->r = r;
    return self;
}
-(int) getx{
    return self->x;
}
-(int) getr{
    return self->r;
}
@end
