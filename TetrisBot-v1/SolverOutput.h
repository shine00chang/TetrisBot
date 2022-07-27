//
//  SolverOutput.h
//  TetrisBot-v1
//
//  Created by Shine Chang on 6/13/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#ifndef SolverOutput_h
#define SolverOutput_h

@interface C_SolverOutput : NSObject{
@public int x;
@public int r;
@public bool hold;
@public int spin;
@public int grid[20][10];
}
-(id) init: (int)x r:(int)r hold:(bool)hold spin:(int)spin;
-(int) getx;
-(int) getr;
-(bool) gethold;
-(int) getspin;
-(int) getGrid: (int)x :(int)y;

-(void) setGrid: (int)x :(int)y val:(int)v;
@end

#endif /* SolverOutput_h */
