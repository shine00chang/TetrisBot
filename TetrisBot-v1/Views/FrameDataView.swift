/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that renders information about a video frame.
*/

import SwiftUI
import ScreenCaptureKit

func ArrayToString (_ arr: [Int]) -> String {
    var str: String = ""
    for i in arr {
        str += " " + String(i)
    }
    return str
}

struct FrameDataView: View {
    @ObservedObject var frame: FrameData
    
    init (frame: FrameData) {
        self.frame = frame
    }
    
    var body: some View {
        VStack {
            Text("Content Rect: \(frame.contentRect.debugDescription)")
            Text(String(format: "Content Scale: %.1f", frame.contentScale))
            Text(String(format: "Scale Factor: %.1f", frame.scaleFactor))
            Text("Surface Size: \(frame.surface.width) x \(frame.surface.height)")
            Text(String(format: "Display Time (sec): %.2f", frame.displayTime))
        }
        .textSelection(.enabled)
    }
}
