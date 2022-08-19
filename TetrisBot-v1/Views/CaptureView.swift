/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's main view.
*/

import SwiftUI
import ScreenCaptureKit
import OSLog
import Combine
import AppTrackingTransparency

var gameData: GameData = GameData();

func redirectLogToDocuments() {
    let path = "/Users/shinechang/Documents/CS/CS-dev/TetrisBot/Logs/log1.txt";
    print("log_path: \(path)");
    freopen(path, "w", stderr);
    //freopen(path, "w", stdout);
}

struct CaptureView: View {

    @StateObject var bot: Bot = Bot()
    @StateObject var screenRecorder: ScreenRecorder = ScreenRecorder()
        
    @State var availableContent: SCShareableContent?
    @State var targetWindow: SCWindow?
    @State var error: Error?
    @State var timer: Cancellable?
             
    @State var grayScale: Bool = true {
        didSet {
            Task () {
                await screenRecorder.stopCapture()
                screenRecorder.grayscale = grayScale
                await screenRecorder.startCapture(with: targetWindow)
            }
        }
    }
    
    private let logger = Logger()

    var filteredWindows: [SCWindow]? {
        availableContent?.windows.sorted {
            $0.owningApplication?.applicationName ?? "" < $1.owningApplication?.applicationName ?? ""
        }
        .filter {
            $0.owningApplication != nil && $0.owningApplication?.applicationName != "" && $0.owningApplication?.applicationName != "Control Center"
        }
    }
    init () {
        redirectLogToDocuments();
    }
    
    var body: some View {
        VStack {
            Form {
                Picker("Window", selection: $targetWindow) {
                    ForEach(filteredWindows ?? [], id: \.self) { window in
                        Text(window.displayName)
                            .tag(SCWindow?.some(window))
                    }
                }
                HStack {
                    if screenRecorder.isRecording {
                        Button("Update Stream") {
                            Task {
                                await screenRecorder.update(with: targetWindow)
                            }
                        }
                    } else {
                        Button("Start Stream") {
                            error = nil
                            Task {
                                await screenRecorder.startCapture(with: targetWindow)
                            }
                        }
                    }
                    
                    Button("Stop Stream") {
                        Task(priority: .high) {
                            await screenRecorder.stopCapture()
                        }
                    }
                    .disabled(!screenRecorder.isRecording)

                    Button("Refresh Available Content") {
                        refreshAvailableContent();
                    }
                }
                Toggle("Show Gray Scale", isOn: $grayScale)
                    .toggleStyle(SwitchToggleStyle())
                Text("Average Frame Data Extraction Time: \(self.screenRecorder.averageFrameDataExtractionTime)")
                bot.controlPannelView
            }
            Divider()
            // Error Messages
            if let error = screenRecorder.error {
                Text(error.localizedDescription)
                    .foregroundColor(.red)
            }
            
            if let error = error {
                Text(error.localizedDescription)
                    .foregroundColor(.red)
            }
        }
        Divider()
        HStack {
            // Bot Control
            ScrollView {
                if let errorMessage = bot.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red);
                }
                TextField("Piece per Second", text: $bot.moveWaitTimeInput)
                    .onReceive(Just(bot.moveWaitTimeInput)) { newValue in
                        let filtered = newValue.filter { "0123456789.".contains($0) }
                        if (filtered != bot.moveWaitTimeInput) {
                            bot.moveWaitTimeInput = filtered;
                        }
                 }
                TextField("Wait Timeout limit", text: $bot.waitTimeoutLimitInput)
                    .onReceive(Just(bot.waitTimeoutLimitInput)) { newValue in
                        let filtered = newValue.filter { "0123456789.".contains($0) }
                        if (filtered != bot.waitTimeoutLimitInput) {
                            bot.waitTimeoutLimitInput = filtered;
                        }
                 }
                // Weight control
                ForEach(bot.weights.indices, id: \.self) { index in
                    HStack {
                        Text(kWeightLabels[index]);
                        TextField("",
                                  text: $bot.weights[index]);
                        Text(bot.weights[index]);
                    }
                    Divider();
                }
            }
            Divider()
            // Image view
            if let frame = screenRecorder.frameData {
        
                DataView();
                Divider()
                
                if let img = frame.image {
                    VStack{
                    FrameDataView(frame: frame)
                        .padding()
                    Divider();
                    Image(decorative: img, scale: 1.0)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    }
                }
            }
        }
        .padding()
        .onAppear {
            timer = RunLoop.current.schedule(after: .init(.now), interval: .seconds(3)) {
                refreshAvailableContent()
            }
            screenRecorder.bot = self.bot;
        }
    }
    
    /// - Tag: GetAvailableContent
    private func refreshAvailableContent() {
        Task {
            do {
                availableContent = try await SCShareableContent.excludingDesktopWindows(false,
                                                                                        onScreenWindowsOnly: true)
                
                // Store the first available window in the local settings.
                if targetWindow == nil {
                    targetWindow = availableContent?.windows.first
                }
            } catch {
                self.error = error
                logger.error("Failed to get the shareable content: \(error.localizedDescription)")
            }
        }
    }
}

extension SCWindow {
    var displayName: String {
        switch (owningApplication, title) {
        case (.some(let application), .some(let title)):
            return "\(application.applicationName): \(title)"
        case (.none, .some(let title)):
            return title
        case (.some(let application), .none):
            return "\(application.applicationName): \(windowID)"
        default:
            return ""
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CaptureView()
    }
}
