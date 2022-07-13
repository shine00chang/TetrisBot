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
    @public int **grid;
    @public int piece;
    @public int hold;
    @public double weights[14];
}
-(id) init;
-(void) setPiece: (const int) piece;
-(void) setHold: (const int) piece;
-(void) setGrid: (int)x :(int)y :(int) grid;
-(void) setWeight: (int)i val:(double)val;
@end;
#endif /* GameData_h */
