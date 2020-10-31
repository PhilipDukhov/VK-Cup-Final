//
//  PrepareVideoStoryViewController.swift
//  Store
//
//  Created by Philip Dukhov on 10/31/20.
//

import UIKit
import Player
import AVFoundation

class PrepareVideoStoryViewController: BasePrepareStoryViewController {
    private enum Constants {
        static let outputDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("exportOutput")
    }
    enum Functionality {
        case photo(UIImage)
        case video(URL)
    }
    
    @IBOutlet weak var trimSlider: TrimSliderControl!
    @IBOutlet weak var muteButton: UIButton!
    
    var videoURL: URL!
    
    private lazy var player = Player().apply {
        $0.playbackDelegate = self
        $0.playerDelegate = self
        $0.view.isUserInteractionEnabled = false
        $0.fillMode = .resizeAspectFill
    }
    
    private var shouldSeekToStartAfterTracking = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        try? FileManager.default
            .removeItem(at: Constants.outputDirectoryURL)
        try? FileManager.default
            .createDirectory(
                at: Constants.outputDirectoryURL,
                withIntermediateDirectories: true
            )
        [trimSlider,
         muteButton
        ].forEach {
            $0.isHidden = true
        }
        view.insertSubview(player.view, at: 0)
        addChild(player)
        trimSlider.isHidden = false
        player.didMove(toParent: self)
        player.url = videoURL
        trimSlider.maxValue = player.asset?.duration.seconds ?? 0
        generateSliderThumbs()
        if let asset = player.asset,
           !asset.tracks(withMediaType: .audio).isEmpty
        {
            muteButton.isHidden = false
            toggleAudioButtonTap(muteButton)
        } else {
            muteButton.isHidden = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        player.view.frame = view.bounds
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        try? FileManager.default
            .removeItem(at: Constants.outputDirectoryURL)
    }
    
    @IBAction func toggleAudioButtonTap(_ sender: UIButton) {
        sender.isSelected.toggle()
        player.muted = sender.isSelected
    }
    
    override func shareButtonTap() {
        player.pause()
        state = .exporting(0)
        export()
    }
    
    @IBAction func trimSliderTouchDown(_ sender: TrimSliderControl) {
        player.pause()
        switch sender.trackingControl {
        case .maxThumb:
            shouldSeekToStartAfterTracking = true
        default:
            break
        }
    }
    
    @IBAction func trimSliderValueChanged(_ sender: TrimSliderControl) {
        guard let timescale = player.asset?.duration.timescale else { return }
        player.seek(to: .init(seconds: sender.value, preferredTimescale: timescale))
    }
    
    @IBAction func trimSliderTouchUpInside() {
        if shouldSeekToStartAfterTracking {
            shouldSeekToStartAfterTracking = false
            playerPlaybackDidEnd(player)
        } else {
            player.playFromCurrentTime()
        }
    }
    
    private func generateSliderTimes(
        containerWidth: CGFloat,
        thumbnailWidth: CGFloat,
        duration: CMTime
    ) -> ([CMTime], CGFloat) {
        let n = Int((containerWidth / thumbnailWidth).rounded(.up))
        var time = CMTime(value: 0, timescale: duration.timescale)
        let step = CGFloat(duration.value) / CGFloat(max(n - 1, 1))
        var times = [CMTime]()
        var i: CGFloat = 0
        repeat {
            if times.count + 1 == n && n > 1 {
                time.value -= 1
            }
            times.append(time)
            i += 1
            time.value = CMTimeValue(step * i)
        } while times.count < n
        return (times, step)
    }
    
    private func generateSliderThumbs() {
        guard let asset = player.asset else { return }
        let containerSize = trimSlider.backgroundView.bounds.size
        let thumbSize = CGSize(side: containerSize.height)
        let duration = asset.duration
        let (times, step) = generateSliderTimes(
            containerWidth: containerSize.width,
            thumbnailWidth: thumbSize.width,
            duration: duration
        )
        trimSlider.backgroundView
            .subviews
            .forEach { $0.removeFromSuperview() }
        let thumbViews: [UIImageView] = (0..<times.count).map {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.frame = .init(
                origin: .init(
                    x: .init($0) * thumbSize.width,
                    y: 0
                ),
                size: thumbSize
            )
            trimSlider.backgroundView.addSubview(imageView)
            return imageView
        }
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.requestedTimeToleranceBefore = CMTime(
            seconds: .init(step),
            preferredTimescale: duration.timescale
        )
        imageGenerator.requestedTimeToleranceAfter = imageGenerator.requestedTimeToleranceBefore
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = .init(
            width: containerSize.height * UIScreen.main.scale,
            height: .infinity
        )
        imageGenerator.generateCGImagesAsynchronously(
            forTimes: times.map(NSValue.init)
        ) { requestedTime, cgImage, _, _, _ in
            guard let image = cgImage, let i = times.firstIndex(of: requestedTime) else { return }
            executeOnMainQueue {
                thumbViews[i].image = .init(cgImage: image)
            }
        }
    }
    
    private func export() {
        guard
            let (composition, videoComposition) = try? generateComposition(),
            let exporter = AVAssetExportSession(
                asset: composition,
                presetName: AVAssetExportPreset1280x720
            )
        else { return }
        
        exporter.timeRange = .init(start: .zero, end: composition.duration)
        exporter.videoComposition = videoComposition
        exporter.outputFileType = .mov
        exporter.outputURL = Constants.outputDirectoryURL
            .appendingPathComponent(NSUUID().uuidString)
            .appendingPathExtension("mov")
        let updateProgressTimer = Timer.scheduledTimer(
            withTimeInterval: 0.3,
            repeats: true
        ) { [weak self] _ in
            self?.state = .exporting(exporter.progress * 0.5)
        }
        exporter.exportAsynchronously { [weak self] in
            executeOnMainQueue {
                defer {
                    updateProgressTimer.fire()
                    updateProgressTimer.invalidate()
                }
                guard let self = self else { return }
                if let error = exporter.error {
                    self.handleUploadResult(.failure(error))
                    return
                }
                self.apiManager
                    .uploadVideo(
                        videoURL: exporter.outputURL!,
                        product: self.attachedProduct
                    ) { progress in
                        executeOnMainQueue { [weak self] in
                            self?.state = .exporting(0.5 + 0.5 * progress)
                        }
                    } completion: { [weak self] in
                        self?.handleUploadResult($0.mapError { $0 })
                    }
            }
        }
    }
    
    override func handleUploadResult(
        _ result: Result<Void, Error>
    ) {
        super.handleUploadResult(result)
        if case .failure = result {
            player.playFromCurrentTime()
        }
    }
    
    private func generateComposition() throws -> (AVComposition, AVVideoComposition)? {
        guard
            let asset = player.asset,
            let videoTrack = asset.tracks(withMediaType: .video).first,
            case let composition = AVMutableComposition(),
            let compositionVideoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
            )
        else { return nil }
        let videoCropRange = CMTimeRange(
            start: .init(
                seconds: trimSlider.minSelectedValue,
                preferredTimescale: videoTrack.naturalTimeScale
            ),
            end: .init(
                seconds: trimSlider.maxSelectedValue,
                preferredTimescale: videoTrack.naturalTimeScale
            )
        )
        try compositionVideoTrack.insertTimeRange(
            videoCropRange,
            of: videoTrack,
            at: .zero
        )
        
        if
            let audioTrack = asset.tracks(withMediaType: .audio).first,
            !muteButton.isSelected,
            let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            )
        {
            try compositionAudioTrack.insertTimeRange(
                videoCropRange,
                of: audioTrack,
                at: .zero
            )
        }
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = .init(
            value: 1,
            timescale: .init(videoTrack.nominalFrameRate)
        )
        
        let screenRatio = UIScreen.main.bounds.aspectRatio
        let videoSize = videoTrack.naturalSize
        let videoTransform = videoTrack.preferredTransform
        var resultSize = CGRect(
            origin: .zero,
            size: videoSize
        ).applying(videoTransform).size
        if resultSize.aspectRatio < screenRatio {
            resultSize.height = ceil(resultSize.width / screenRatio)
        } else {
            resultSize.width = ceil(resultSize.height * screenRatio)
        }
        let compositionInstruction = AVMutableVideoCompositionInstruction()
        compositionInstruction.timeRange = CMTimeRange(
            start: .zero,
            duration: videoCropRange.duration
        )
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(
            assetTrack: videoTrack
        )
        layerInstruction.setTransform(videoTransform, at: .zero)
        compositionInstruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [compositionInstruction]
        videoComposition.renderSize = resultSize
        
        let parentLayer = CALayer()
        let overlayLayer = CALayer()
        let videoLayer = CALayer()
        let image = renderProductView()
        overlayLayer.contents = image.cgImage
        
        var scale: CGFloat = player.view.bounds.width / resultSize.width
        if player.view.bounds.height * scale < player.view.bounds.height {
            scale = player.view.bounds.height / resultSize.height
        }
        
        overlayLayer.frame = productView.frame
            .applying(
                .init(
                    scaleX: 1 / scale,
                    y: 1 / scale
                )
            )
        overlayLayer.frame.origin.y = resultSize.height - overlayLayer.frame.maxY
        videoLayer.frame.size = resultSize
        overlayLayer.masksToBounds = true
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(overlayLayer)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: parentLayer
        )
        
        return (composition, videoComposition)
    }
}

extension PrepareVideoStoryViewController: PlayerDelegate {
    func playerReady(_ player: Player) {
        player.playFromCurrentTime()
    }
    
    func playerPlaybackStateDidChange(_ player: Player) {
        
    }
    
    func playerBufferingStateDidChange(_ player: Player) {
        
    }
    
    func playerBufferTimeDidChange(_ bufferTime: Double) {
        
    }
    
    func player(_ player: Player, didFailWithError error: Error?) {
        
    }
}

extension PrepareVideoStoryViewController: PlayerPlaybackDelegate {
    public func playerCurrentTimeDidChange(_ player: Player) {
        guard case .idle = state else {
            player.pause()
            return
        }
        guard !trimSlider.seeking else { return }
        trimSlider.value = player.currentTimeInterval
        if trimSlider.value >= trimSlider.maxSelectedValue {
            playerPlaybackDidEnd(player)
        }
    }
    
    public func playerPlaybackWillStartFromBeginning(_ player: Player) {}
    
    public func playerPlaybackDidEnd(_ player: Player) {
        player.seekToTime(
            to: .init(
                seconds: trimSlider.minSelectedValue,
                preferredTimescale: player.asset!.duration.timescale
            ),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
        { [weak self] _ in
            guard case .idle = self?.state else { return }
            player.playFromCurrentTime()
        }
    }
    
    public func playerPlaybackWillLoop(_ player: Player) { }
    
    public func playerPlaybackDidLoop(_ player: Player) { }
}
