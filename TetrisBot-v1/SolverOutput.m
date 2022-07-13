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
-(id) init: (int)x r:(int)r hold:(bool)hold spin:(int)spin{
    self = [super init];
    self->x = x;
    self->r = r;
    self->spin = spin;
    self->hold = hold;
    return self;
}
-(int) getx{
    return self->x;
}
-(int) getr{
    return self->r;
}
-(bool) gethold{
    return self->hold;
}
-(int) getspin {
    return self->spin;
}
@end
