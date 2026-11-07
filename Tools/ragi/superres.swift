// Cihaz içi süper çözünürlük (VideoToolbox). Girdi: düz zeminli PNG, çıktı: büyütülmüş PNG.
//   swiftc Tools/ragi/superres.swift -o /tmp/superres && /tmp/superres girdi.png cikti.png
import CoreImage
import Foundation
import ImageIO
import VideoToolbox

let args = CommandLine.arguments
let ci = CIImage(contentsOf: URL(fileURLWithPath: args[1]))!
let w = Int(ci.extent.width), h = Int(ci.extent.height)
let context = CIContext()

func buffer(_ attrs: [String: Any], _ width: Int, _ height: Int) -> CVPixelBuffer {
    var merged = attrs
    merged[kCVPixelBufferWidthKey as String] = width
    merged[kCVPixelBufferHeightKey as String] = height
    let format = (attrs[kCVPixelBufferPixelFormatTypeKey as String] as? [NSNumber])?.first?.uint32Value
        ?? (attrs[kCVPixelBufferPixelFormatTypeKey as String] as? NSNumber)?.uint32Value ?? kCVPixelFormatType_32BGRA
    var out: CVPixelBuffer?
    CVPixelBufferCreate(nil, width, height, format, merged as CFDictionary, &out)
    return out!
}

let done = DispatchSemaphore(value: 0)
Task {
    defer { done.signal() }
    print("destek:", VTSuperResolutionScalerConfiguration.isSupported, VTSuperResolutionScalerConfiguration.supportedScaleFactors)
    let factor = VTSuperResolutionScalerConfiguration.supportedScaleFactors.max() ?? 4
    guard let config = VTSuperResolutionScalerConfiguration(frameWidth: w, frameHeight: h, scaleFactor: factor,
                                                            inputType: .image, usePrecomputedFlow: false,
                                                            qualityPrioritization: .normal, revision: VTSuperResolutionScalerConfiguration.defaultRevision)
    else { print("yapılandırma yok (boyut?)", w, h); return }
    if config.configurationModelStatus != .ready {
        print("model indiriliyor")
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            config.downloadConfigurationModel { e in if let e { c.resume(throwing: e) } else { c.resume() } }
        }
    }
    let processor = VTFrameProcessor()
    try processor.startSession(configuration: config)
    let src = buffer(config.sourcePixelBufferAttributes, w, h)
    context.render(ci, to: src)
    let dst = buffer(config.destinationPixelBufferAttributes, w * factor, h * factor)
    let time = CMTime(value: 0, timescale: 600)
    let params = VTSuperResolutionScalerParameters(sourceFrame: VTFrameProcessorFrame(buffer: src, presentationTimeStamp: time)!,
                                                   previousFrame: nil, previousOutputFrame: nil, opticalFlow: nil,
                                                   submissionMode: .random,
                                                   destinationFrame: VTFrameProcessorFrame(buffer: dst, presentationTimeStamp: time)!)!
    try await processor.process(parameters: params)
    processor.endSession()
    try context.writePNGRepresentation(of: CIImage(cvPixelBuffer: dst), to: URL(fileURLWithPath: args[2]),
                                       format: .RGBA8, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)
    print("yazıldı", w * factor, h * factor)
}
done.wait()
