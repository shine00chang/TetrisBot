/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that renders a video frame.
*/

import SwiftUI

struct FrameView: NSViewRepresentable {
    
    @ObservedObject var frame: FrameData
    
    init(_ frame: FrameData) {
        self.frame = frame
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        if view.layer == nil {
            view.makeBackingLayer()
        }
        view.layer?.contents = frame.surface
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.layer?.contents = frame.surface
    }
}
