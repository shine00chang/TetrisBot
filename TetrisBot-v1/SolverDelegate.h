//
//  SolverDelegate.h
//  TetrisBot-v1
//
//  Created by Shine Chang on 5/22/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#ifndef SolverDelegate_h
#define SolverDelegate_h

#define SOLVER_LOG

#import <Foundation/Foundation.h>
#include "GameData.h"
#include "SolverOutput.h"

@interface SolverDelegate : NSObject
+(C_SolverOutput*) runSolver: (C_GameData*) game pTime:(double)pTime shouldMove:(bool)shouldMove first:(bool)first; 

@end

#endif /* SolverDelegate_h */
