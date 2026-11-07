#!/usr/bin/env swift
// Simülatör kaydına Ragi'nin seslerini ekler (simctl kaydı sessizdir).
// Sahne geçişleri zemin renginden bulunur, ses o ana yerleşir.
//
//   xcrun simctl launch <cihaz> com.batu.magicpaper.v1 -mpDemo YES -mpRagiStudio YES
//   xcrun simctl io <cihaz> recordVideo kayit.mov     (bir tur, 30 sn)
//   swift Tools/record_ragi_preview.swift kayit.mov MagicPaper/DesignSystem/Sounds cikti.mp4 [kareler/]
import AVFoundation
import AppKit

let args = CommandLine.arguments
let input = URL(fileURLWithPath: args[1]), sounds = URL(fileURLWithPath: args[2]), output = URL(fileURLWithPath: args[3])
let framesDir = args.count > 4 ? args[4] : nil
let sceneLength = 4.0
// `RagiStudioView.scenes` sırası.
let cues: [String?] = ["mp_ragi", "mp_ending", "mp_ready", "mp_page", "mp_earned", nil, nil]

let semaphore = DispatchSemaphore(value: 0)
Task {
    let asset = AVURLAsset(url: input)
    let duration = try await asset.load(.duration).seconds
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.requestedTimeToleranceBefore = .zero
    generator.requestedTimeToleranceAfter = .zero

    func cornerColor(_ t: Double) async throws -> [Int] {
        let (cg, _) = try await generator.image(at: CMTime(seconds: t, preferredTimescale: 600))
        let rep = NSBitmapImageRep(cgImage: cg)
        let c = rep.colorAt(x: 8, y: cg.height / 3)!.usingColorSpace(.deviceRGB)!
        return [Int(c.redComponent * 255), Int(c.greenComponent * 255), Int(c.blueComponent * 255)]
    }

    var changes: [Double] = []
    var last: [Int]? = nil
    var t = 0.0
    while t < duration {
        let c = try await cornerColor(t)
        if let l = last, zip(l, c).contains(where: { abs($0 - $1) > 6 }) { changes.append(t) }
        last = c
        t += 0.1
    }
    print("geçişler:", changes.map { String(format: "%.1f", $0) }.joined(separator: " "))
    // Açılışın ilk zemini ilk sahnedir (son yakın değişim); sonrakiler birer sahne.
    var starts: [Double] = []
    for change in changes where starts.last.map({ change - $0 > 2 }) ?? true { starts.append(change) }
    let start = starts.first ?? 0

    let comp = AVMutableComposition()
    let videoTrack = try await asset.loadTracks(withMediaType: .video)[0]
    let video = comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
    try video.insertTimeRange(CMTimeRange(start: .zero, duration: CMTime(seconds: duration, preferredTimescale: 600)),
                              of: videoTrack, at: .zero)
    video.preferredTransform = try await videoTrack.load(.preferredTransform)

    for (i, cue) in cues.enumerated() {
        guard let cue else { continue }
        guard starts.indices.contains(i) else { continue }
        let at = starts[i]
        let audioAsset = AVURLAsset(url: sounds.appendingPathComponent(cue + ".m4a"))
        let source = try await audioAsset.loadTracks(withMediaType: .audio)[0]
        let d = try await audioAsset.load(.duration)
        let track = comp.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
        try track.insertTimeRange(CMTimeRange(start: .zero, duration: d), of: source,
                                  at: CMTime(seconds: at, preferredTimescale: 600))
    }

    try? FileManager.default.removeItem(at: output)
    let export = AVAssetExportSession(asset: comp, presetName: AVAssetExportPreset1920x1080)!
    try await export.export(to: output, as: .mp4)
    print("yazıldı:", output.path, "sahne başlangıcı:", String(format: "%.1f", start))

    if let framesDir {
        try FileManager.default.createDirectory(atPath: framesDir, withIntermediateDirectories: true)
        // Her sahneden hareketin farklı anları.
        for scene in 0..<cues.count {
            for offset in [0.45, 0.75, 1.05] {
                let at = start + Double(scene) * sceneLength + offset
                guard at >= 0, at < duration else { continue }
                let (cg, _) = try await generator.image(at: CMTime(seconds: at, preferredTimescale: 600))
                let data = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])!
                try data.write(to: URL(fileURLWithPath: "\(framesDir)/s\(scene)_\(Int(offset * 100)).png"))
            }
        }
    }
    semaphore.signal()
}
semaphore.wait()
