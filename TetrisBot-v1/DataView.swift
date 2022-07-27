//
//  GridView.swift
//  TetrisBot-v1
//
//  Created by Shine Chang on 7/3/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

struct DataView: View {
    let blockSize: CGFloat = 10;
    @ObservedObject var data = gameData;
    
    var body: some View {
        VStack (spacing: 2) {
            Divider()
            
            Text("Current Piece: \(data.piece.rawValue)")
            Text("Hold Piece: \(data.hold.rawValue)")
            ForEach (data.grid, id: \.self) { row in
                HStack (spacing: 2) {
                    ForEach (row, id: \.self) { cell in
                        Rectangle()
                            .fill(Color(color: pieceColor[cell]!))
                            .frame(width: self.blockSize, height: self.blockSize)
                            .padding(CGFloat(0))
                    }
                }
            }
            Divider();
            ForEach (data.predictionGrid, id: \.self) { row in
                HStack (spacing: 2) {
                    ForEach (row, id: \.self) { cell in
                        Rectangle()
                            .fill(Color(color: pieceColor[cell]!))
                            .frame(width: self.blockSize, height: self.blockSize)
                            .padding(CGFloat(0))
                    }
                }
            }
        }
    }
}
