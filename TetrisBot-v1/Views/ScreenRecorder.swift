/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An object that captures a stream of screen content.
*/

import Foundation
import ScreenCaptureKit
import OSLog
import VideoToolbox
import Accelerate

let divisor: Int32 = 0x1000
let fDivisor = Float(divisor)

var coefficientsMatrix = [
    Int16(0.2126 * fDivisor),
    Int16(0.7152 * fDivisor),
    Int16(0.0722 * fDivisor)
]


struct Position {
    var x: Int
    var y: Int
}

func machTimeToSeconds(_ machTime: UInt64) -> TimeInterval {
    var timebase = mach_timebase_info_data_t()
    mach_timebase_info(&timebase)
    let nanoseconds = machTime * UInt64(timebase.numer) / UInt64(timebase.denom)
    return Double(nanoseconds) / Double(kSecondScale)
}

class ScreenRecorder: NSObject, ObservableObject {
    
    struct ScreenRecorderError: Error {
        let errorDescription: String
        
        init(_ description: String) {
            errorDescription = description
        }
    }
    
    var bot: Bot? = nil;
    @Published var frameData: FrameData?
    @Published var error: Error?
    @Published var isRecording = false
    @Published var averageFrameDataExtractionTime: Double = 0;
    
    var grayscale: Bool = true
    
    private var stream: SCStream?
    private let logger = Logger()
    private var cpuStartTime = mach_absolute_time()
    private let frameOutputQueue = DispatchQueue(label: "frame-handling")

    /// - Tag: StartCapture
    @MainActor
    func startCapture(with window: SCWindow?) async {
        error = nil
        isRecording = false
        
        do {
            // Create the content filter with the sample app settings.
            let filter = try await contentFilter(for: window)
            
            // Create the stream configuration with the sample app settings.
            let streamConfig = streamConfiguration(for: window)
            
            // Create a capture stream with the filter and stream configuration.
            stream = SCStream(filter: filter, configuration: streamConfig, delegate: self)
            
            // Add a stream output to capture screen content.
            try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: frameOutputQueue)
            
            // Start the capture session.
            try await stream?.startCapture()
            
            cpuStartTime = mach_absolute_time()
            isRecording = true
        } catch {
            logger.error("Failed to start the stream session: \(String(describing: error))")
            self.error = error
        }
    }
    
    /// - Tag: UpdateCaptureConfig
    @MainActor
    func update(with window: SCWindow?) async {
        do {
            let filter = try await contentFilter(for: window)
            let streamConfig = streamConfiguration(for: window)
            try await stream?.updateConfiguration(streamConfig)
            try await stream?.updateContentFilter(filter)
        } catch {
            logger.error("Failed to update the stream session: \(String(describing: error))")
            self.error = error
        }
    }
    
    @MainActor
    func stopCapture() async {
        isRecording = false
        do {
            try await stream?.stopCapture()
        } catch {
            logger.error("Failed to stop the stream session: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    /// - Tag: CreateContentFilter
    private func contentFilter(for window: SCWindow?) async throws -> SCContentFilter {
        let filter: SCContentFilter
        if let window = window {
            // Create a content filter that includes a single window.
            filter = SCContentFilter(desktopIndependentWindow: window)
        } else {
            throw ScreenRecorderError("The configuration doesn't provide a display or window.")
        }
        return filter
    }
    
    /// - Tag: CreateStreamConfiguration
    private func streamConfiguration(for window: SCWindow?) -> SCStreamConfiguration {
        let streamConfig = SCStreamConfiguration()
        
        // Set the capture interval at 20 fps.
        streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(20))
        
        // Increase the depth of the frame queue to ensure high fps at the expense of increasing
        // the memory footprint of WindowServer.
        streamConfig.queueDepth = 5
        
        return streamConfig
    }
}

extension ScreenRecorder: SCStreamOutput {
        
    /// - Tag: DidOutputSampleBuffer
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        
        let startTime = mach_absolute_time()
        guard sampleBuffer.isValid else {
            logger.log("The sample buffer is invalid.")
            return
        }

        // Retrieve the dictionary of metadata attachments from the sample buffer.
        // You use the attachments to retrieve data about the captured frame.
        guard let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true) as? [[SCStreamFrameInfo: Any]],
              let attachments = attachmentsArray.first else {
            logger.error("Failed to retrieve the attachments from the sample buffer.")
            return
        }

        guard let statusRawValue = attachments[SCStreamFrameInfo.status] as? Int,
              let status = SCFrameStatus(rawValue: statusRawValue) else {
            logger.error("Failed to get the frame status from the attachments.")
            return
        }
        
        guard status == .complete else {
            logger.log("Skip updating the frame because the frame status is \(String(describing: status))")
            return
        }

        guard let pixelBuffer = sampleBuffer.imageBuffer else {
            logger.error("Failed to get a pixel buffer from the sample buffer.")
            return
        }

        guard let surfaceRef = CVPixelBufferGetIOSurface(pixelBuffer)?.takeUnretainedValue() else {
            logger.error("Could not get an IOSurface from the pixel buffer.")
            return
        }

        guard let contentRectDict = attachments[.contentRect],
              let contentRect = CGRect(dictionaryRepresentation: contentRectDict as! CFDictionary) else {
            logger.error("Failed to get a content rectangle from the sample buffer.")
            return
        }

        guard let displayTime = attachments[.displayTime] as? UInt64 else {
            logger.error("Failed to get a display time from the sample buffer.")
            return
        }
        let elapsedTime = machTimeToSeconds(displayTime) - machTimeToSeconds(cpuStartTime)

        guard let contentScale = attachments[.contentScale] as? Double else {
            logger.error("Failed to get the contentScale from the sample buffer.")
            return
        }

        guard let scaleFactor = attachments[.scaleFactor] as? Double else {
            logger.error("Failed to get the scaleFactor from the sample buffer.")
            return
        }
        // Force-cast the IOSurfaceRef to IOSurface.
        let surface = unsafeBitCast(surfaceRef, to: IOSurface.self)
        toGrayscale(pixelBuffer)
        var image: CGImage? = nil
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer,
                                         options: nil,
                                         imageOut: &image)
        if image == nil {
            logger.error("Failed to create CGImage from pixelBuffer.")
            return
        }

        
        // Publish the new captured frame.
        DispatchQueue.main.async {
            self.frameData = FrameData(pixelBuffer: pixelBuffer,
                                             surface: surface,
                                             image: image!,
                                             contentRect: contentRect,
                                             displayTime: elapsedTime,
                                             contentScale: contentScale,
                                             scaleFactor: scaleFactor)
            if isValidGameFrame(self.frameData!) {
                Bot.getGame(from: self.frameData!.pixelBuffer);
                Bot.markGridPoints(for: self.frameData!.pixelBuffer)
                self.bot?.checkRun();
            }
            self.averageFrameDataExtractionTime += machTimeToSeconds( mach_absolute_time() - startTime );
            self.averageFrameDataExtractionTime /= 2;
        }
    }
}

extension ScreenRecorder: SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        DispatchQueue.main.async {
            self.logger.error("Stream stopped with error: \(error.localizedDescription)")
            self.error = error
            self.isRecording = false
        }
    }
}


