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
}
-(id) init: (int)x r:(int)r;
-(int) getx;
-(int) getr;
@end

#endif /* SolverOutput_h */
