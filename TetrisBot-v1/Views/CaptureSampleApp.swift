/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The entry point into this app.
*/
import SwiftUI

@main
struct CaptureSampleApp: App {
    var body: some Scene {
        WindowGroup {
            CaptureView()
                .frame(minWidth: 600, minHeight: 600, alignment: .center)
        }
    }
}
