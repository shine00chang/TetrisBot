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
    @public int piece;
}
-(id) init;
-(int) getPiece;
-(void) setPiece: (const int) piece;
-(void) setGrid: (int)x :(int)y :(int) grid;

@end;
#endif /* GameData_h */
