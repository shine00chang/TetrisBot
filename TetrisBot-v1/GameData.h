//
//  GameData.h
//  TetrisBot-v1
//
//  Created by Shine Chang on 6/13/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#ifndef GameData_h
#define GameData_h

#import <Foundation/Foundation.h>

@interface C_GameData: NSObject {
    @public int grid[20][10];
    @public int *pieces;
    @public int hold;
    @public double weights[18];
}
-(id) init;
-(void) setPieces: (int)i :(const int) piece;
-(void) setHold: (const int) piece;
-(void) setGrid: (int)x :(int)y :(int) grid;
-(void) setWeight: (int)i val:(double)val;
@end;
#endif /* GameData_h */
