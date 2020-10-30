//
//  CameraViewController.swift
//  VK-Cup-C-Camera
//
//  Created by Philip Dukhov on 2/25/20.
//  Copyright © 2020 Philip Dukhov. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    enum Link: Hashable {
        case product(String)
        case group(Int)
        
        init?(string: String) {
            guard
                let url = URL(string: string),
                let urlComponents = URLComponents(
                    url: url,
                    resolvingAgainstBaseURL: false
                ),
                urlComponents.host == "vk.com",
                case let components = urlComponents.path.split(separator: "-"),
                components.count == 2,
                components[0] == "/market",
                let groupId = Int(components[1])
            else { return nil }
            if urlComponents.queryItems?.isEmpty != false {
                self = .group(groupId)
                return
            }
            guard let queryItems = urlComponents.queryItems,
                let productId = Self.resolveProductId(queryItems)
            else { return nil }
            self = .product(productId)
        }
        
        static func resolveProductId(
            _ queryItems: [URLQueryItem]
        ) -> String? {
            let wPrefix = "product"
            guard
                let w = queryItems
                    .first(where: { $0.name == "w" })?
                    .value,
                w.hasPrefix(wPrefix)
            else { return nil }
            return String(
                w.suffix(
                    from: w.index(
                        w.startIndex,
                        offsetBy: wPrefix.count
                    )
                )
            )
        }
    }
    
    private enum Constants {
        static let pressDurationUntilRecordingStarts: TimeInterval = 0.7
        static let maxRecordedDuration: TimeInterval = 5
        static let outputDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("cameraOutput")
        static let qrAnimationDuration: TimeInterval = 0.3
    }
    enum Functionality {
        case qrReader
        case recorder
    }
    
    var functionality: Functionality = .qrReader
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewView.session = session
        previewView.videoPreviewLayer.videoGravity = .resizeAspectFill
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
            
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(
                for: .video
            ) { [self] granted in
                if !granted {
                    setupResult = .notAuthorized
                }
                sessionQueue.resume()
            }
            
        default:
            setupResult = .notAuthorized
        }
        sessionQueue.async { [self] in
            configureSession()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(
            true,
            animated: animated
        )
        
        try? FileManager.default.removeItem(
            at: Constants.outputDirectoryURL
        )
        try? FileManager.default.createDirectory(
            at: Constants.outputDirectoryURL,
            withIntermediateDirectories: true
        )
        flashButton.isSelected = false
        noCameraAccessView.isHidden = true
        captureControlsContainer.isHidden = true
        
        sessionQueue.async { [self] in
            switch setupResult {
            case .success:
                session.startRunning()
                isSessionRunning = session.isRunning
                executeOnMainQueue {
                    switch functionality {
                    case .qrReader:
                        break
                        
                    case .recorder:
                        captureControlsContainer.isHidden = false
                    }
                }
                
            case .notAuthorized:
                executeOnMainQueue {
                    noCameraAccessView.isHidden = false
                }
                
            case .configurationFailed:
                executeOnMainQueue {
                    let alertMsg = "Alert message when something goes wrong during capture session configuration"
                    let message = NSLocalizedString("Unable to capture media", comment: alertMsg)
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async { [self] in
            if setupResult == .success {
                session.stopRunning()
                isSessionRunning = session.isRunning
            }
        }
        navigationController?.setNavigationBarHidden(
            false, animated: animated
        )
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        captureButton.buttonState = .default
    }
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    private let session = AVCaptureSession()
    private var isSessionRunning = false
    private let sessionQueue = DispatchQueue(label: "session queue")
    private var setupResult: SessionSetupResult = .success
    @objc private dynamic var videoDeviceInput: AVCaptureDeviceInput!
    private var qrDetectorLayers = [Link: CAShapeLayer]()
    private let apiManager = LinkResolverApiManager()
    
    private func configureSession() {
        if setupResult != .success {
            return
        }
        
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        do {
            let deviceType: AVCaptureDevice.DeviceType
            if #available(iOS 10.2, *) {
                deviceType = .builtInDualCamera
            } else {
                deviceType = .builtInTelephotoCamera
            }
            let variants: [(AVCaptureDevice.DeviceType, AVCaptureDevice.Position)] = [
                (deviceType, .back),
                (.builtInWideAngleCamera, .back),
                (.builtInWideAngleCamera, .front),
            ]
            guard
                let videoDevice = variants
                    .compactMap({ deviceType, position in
                        AVCaptureDevice.default(
                            deviceType,
                            for: .video,
                            position: position
                        )
                    }).first
            else {
                throw NSError(description: "Default video device is unavailable.")
            }
            let videoDeviceInput = try AVCaptureDeviceInput(
                device: videoDevice
            )
            
            guard session.canAddInput(videoDeviceInput) else {
                throw NSError(description: "Couldn't add video device input to the session.")
            }
            session.addInput(videoDeviceInput)
            self.videoDeviceInput = videoDeviceInput
            
            executeOnMainQueue { [self] in
                flashButton.alpha = videoDeviceInput.device.hasTorch ? 1 : 0
                previewView.videoPreviewLayer.connection?.videoOrientation = .portrait
            }
        } catch {
            print("Couldn't create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        do {
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
            
            if session.canAddInput(audioDeviceInput) {
                session.addInput(audioDeviceInput)
            } else {
                print("Could not add audio device input to the session")
            }
        } catch {
            print("Could not create audio device input: \(error)")
        }
        
        let movieFileOutput = AVCaptureMovieFileOutput()
        movieFileOutput.maxRecordedDuration = .init(seconds: Constants.maxRecordedDuration, preferredTimescale: 600)
        
        if session.canAddOutput(movieFileOutput) {
            session.beginConfiguration()
            session.addOutput(movieFileOutput)
            session.sessionPreset = .high
            if let connection = movieFileOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
            session.commitConfiguration()
            
            self.movieFileOutput = movieFileOutput
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }
        
        session.commitConfiguration()
    }
    
    private enum CaptureMode: Int {
        case photo = 0
        case movie = 1
    }
    
    @IBOutlet private weak var previewView: PreviewView!
    @IBOutlet private weak var captureButton: CaptureButton!
    @IBOutlet private weak var flashButton: UIButton!
    @IBOutlet private weak var toggleCameraButton: UIButton!
    @IBOutlet private weak var configButtonsContainer: UIView!
    @IBOutlet private weak var noCameraAccessView: UIView!
    @IBOutlet private weak var captureControlsContainer: UIView!
    
    private let videoDeviceDiscoverySession: AVCaptureDevice.DiscoverySession = {
        var deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera,
            .builtInTelephotoCamera
        ]
        if #available(iOS 10.2, *) {
            deviceTypes.append(.builtInDualCamera)
        }
        if #available(iOS 11.1, *) {
            deviceTypes.append(.builtInTrueDepthCamera)
        }
        return AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .unspecified
        )
    }()
    
    private var movieFileOutput: AVCaptureMovieFileOutput!
    
    private var backgroundRecordingID: UIBackgroundTaskIdentifier = .invalid
    private weak var recordTimer: Timer?
    
    @IBAction private func settingsButtonTap() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }
    
    @IBAction private func toggleFlash() {
        sessionQueue.async { [self] in
            defer {
                executeOnMainQueue {
                    flashButton.isSelected = videoDeviceInput.device.torchMode == .on
                }
            }
            let device = videoDeviceInput.device
            guard device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                guard device.torchMode != .on else {
                    device.torchMode = .off
                    return
                }
                do {
                    try device.setTorchModeOn(level: 1.0)
                } catch {
                    print("[toggleFlash]: \(error)")
                }
                device.unlockForConfiguration()
            } catch {
                print("[toggleFlash]: \(error)")
            }
        }
    }
    
    @IBAction private func toggleCamera() {
        captureButton.isEnabled = false
        
        sessionQueue.async { [self] in
            let currentVideoDevice = videoDeviceInput.device
            let currentPosition = currentVideoDevice.position
            
            let preferredPosition: AVCaptureDevice.Position
            let preferredDeviceType: AVCaptureDevice.DeviceType
            
            switch currentPosition {
            case .back:
                preferredPosition = .front
                if #available(iOS 11.1, *) {
                    preferredDeviceType = .builtInTrueDepthCamera
                } else {
                    preferredDeviceType = .builtInTelephotoCamera
                }
                
            default:
                preferredPosition = .back
                if #available(iOS 10.2, *) {
                    preferredDeviceType = .builtInDualCamera
                } else {
                    preferredDeviceType = .builtInTelephotoCamera
                }
            }
            let devices = videoDeviceDiscoverySession.devices
            // First, seek a device with both the preferred position and device type. Otherwise, seek a device with only the preferred position.
            defer {
                executeOnMainQueue {
                    captureButton.isEnabled = true
                    let hasTorch = videoDeviceInput.device.hasTorch
                    if hasTorch {
                        flashButton.isSelected = videoDeviceInput.device.torchMode == .on
                    }
                    UIView.animate(withDuration: 0.3) {
                        flashButton.alpha = hasTorch ? 1 : 0
                    }
                }
            }
            
            guard let videoDevice =
                devices.first(where: { $0.position == preferredPosition && $0.deviceType == preferredDeviceType }) ??
                devices.first(where: { $0.position == preferredPosition })
            else { return }
            do {
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                
                session.beginConfiguration()
                
                session.removeInput(videoDeviceInput)
                
                if session.canAddInput(videoDeviceInput) {
                    session.addInput(videoDeviceInput)
                    self.videoDeviceInput = videoDeviceInput
                } else {
                    session.addInput(videoDeviceInput)
                }
                if let connection = movieFileOutput?.connection(
                    with: .video
                ), connection.isVideoStabilizationSupported
                {
                    connection.preferredVideoStabilizationMode = .auto
                }
                
                session.commitConfiguration()
            } catch {
                print("Error occurred while creating video device input: \(error)")
            }
        }
    }
    
    @IBAction private func tap(_ sender: UIGestureRecognizer) {
        let location = sender.location(in: view)
        var nearestQR: (Link?, CGFloat) = (nil, CGFloat.greatestFiniteMagnitude)
        
        for (link, layer) in qrDetectorLayers {
            if let distance = layer.frame.controlDistanceFromMid(to: location),
               distance < nearestQR.1
            {
                nearestQR = (link, distance)
            }
        }
        switch nearestQR.0 {
        case .group(let groupId):
            apiManager.getGroupIfHasMarket(
                groupId: groupId
            ) { [weak self] result in
                switch result {
                case .success(let group):
                    executeOnMainQueue {
                        self?.navigate(to: group)
                    }
                    
                case .failure(let error):
                    print(error)
                }
            }
            
        case .product(let productId):
            apiManager.getProduct(
                productId: productId
            ) { [weak self] result in
                switch result {
                case .success(let product):
                    executeOnMainQueue {
                        self?.navigate(to: product)
                    }
                    
                case .failure(let error):
                    print(error)
                }
            }
            
        case .none: break
        }
    }
    
    @IBAction private func closeButtonTap() {
        navigationController?.popViewController(animated: true)
    }
    
    private func navigate(to group: Group) {
        navigationController?.replaceTopController(
            with: R.storyboard.main.productsListViewController()!.apply {
                $0.initialInfo = .init(group: group)
            },
            animated: true
        )
    }
    
    private func navigate(to product: Product) {
        navigationController?.replaceTopController(
            with: R.storyboard.main.productPageViewController()!.apply {
                $0.initialInfo = .init(product: product)
            },
            animated: true
        )
    }
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        captureButton.buttonState = .recording(maxDuration: Constants.maxRecordedDuration)
        UIView.animate(withDuration: 0.3) { [self] in
            configButtonsContainer.alpha = 0
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        endRecording()
        func cleanup() {
            let path = outputFileURL.path
            if FileManager.default.fileExists(atPath: path) {
                do {
                    try FileManager.default.removeItem(atPath: path)
                } catch {
                    print("Could not remove file at url: \(outputFileURL)")
                }
            }
            
            if backgroundRecordingID != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundRecordingID)
                backgroundRecordingID = .invalid
            }
        }
        
        var success = true
        
        if error != nil {
            success = (((error! as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as AnyObject).boolValue)!
            if !success {
                print("Movie file finishing error: \(String(describing: error))")
            }
        }
        
        if success {
            performSegue(withIdentifier: "trim", sender: outputFileURL)
        } else {
            cleanup()
        }
    }
}

extension CameraViewController: CaptureButtonDelegate {
    func captureButton(_ button: CaptureButton, zoomChanged zoom: CGFloat) {
        guard #available(iOS 11.0, *) else { return }
        sessionQueue.async { [self] in
            let device = videoDeviceInput.device
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = device.minAvailableVideoZoomFactor + (device.maxAvailableVideoZoomFactor - device.minAvailableVideoZoomFactor) * zoom
                device.unlockForConfiguration()
            } catch {
                print("[toggleFlash]: \(error)")
            }
        }
    }
    
    func captureButtonBeginTracking(_ button: CaptureButton) {
        guard movieFileOutput != nil else { return }
        button.buttonState = .preparingToRecord
        recordTimer = .scheduledTimer(
            withTimeInterval: Constants.pressDurationUntilRecordingStarts,
            repeats: false
        ) { [weak self] _ in
            self?.beginRecording()
        }
    }
    
    func captureButtonEndTracking(_ button: CaptureButton) {
        endRecording()
    }
    
    private func beginRecording() {
        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation
        
        sessionQueue.async { [self] in
            if UIDevice.current.isMultitaskingSupported {
                backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
            }
            
            let movieFileOutputConnection = movieFileOutput.connection(with: .video)
            movieFileOutputConnection?.videoOrientation = videoPreviewLayerOrientation!
            
            let availableVideoCodecTypes = movieFileOutput.availableVideoCodecTypes
            
            if #available(iOS 11.0, *) {
                if availableVideoCodecTypes.contains(.hevc) {
                    movieFileOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: movieFileOutputConnection!)
                }
            }
            
            let outputURL = Constants.outputDirectoryURL
                .appendingPathComponent(NSUUID().uuidString)
                .appendingPathExtension("mov")
            movieFileOutput.startRecording(to: outputURL, recordingDelegate: self)
        }
    }
    
    private func endRecording() {
        recordTimer?.invalidate()
        captureButton.buttonState = .recorded
        sessionQueue.async { [self] in
            if movieFileOutput.isRecording {
                movieFileOutput.stopRecording()
            }
            
            executeOnMainQueue {
                UIView.animate(withDuration: 0.3) {
                    configButtonsContainer.alpha = 1
                }
            }
        }
    }
}

extension CameraViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        var oldLayers = qrDetectorLayers
        qrDetectorLayers.removeAll()
        metadataObjects
            .compactMap { $0 as? AVMetadataMachineReadableCodeObject }
            .forEach { metadata in
                guard
                    let transformedMetadata = previewView.videoPreviewLayer.transformedMetadataObject(for: metadata),
                    let string = metadata.stringValue,
                    let link = Link(string: string),
                    qrDetectorLayers[link] == nil else { return }
                let layer = oldLayers.removeValue(forKey: link) ?? initializeLayer()
                layer.frame = transformedMetadata.bounds
                animate(layer: layer, appearance: true, progress: (layer.presentation() ?? layer).opacity)
                layer.path = qrRectPath(for: .init(origin: .zero, size: transformedMetadata.bounds.size))
                qrDetectorLayers[link] = layer
            }
        oldLayers.forEach {
            let (string, layer) = $0
            let opacity = (layer.presentation() ?? layer).opacity
            if opacity > 0 {
                animate(layer: layer, appearance: false, progress: 1 - opacity) { [weak self] in
                    if (layer.presentation() ?? layer).opacity == 0 {
                        layer.removeFromSuperlayer()
                        self?.qrDetectorLayers[string] = nil
                    }
                }
                qrDetectorLayers[string] = layer
            } else {
                layer.removeFromSuperlayer()
            }
        }
    }
    
    private func initializeLayer() -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.frame = view.bounds
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 2
        layer.strokeColor = UIColor(rgb: 0xFECE00).cgColor
        layer.opacity = 0.01
        view.layer.addSublayer(layer)
        return layer
    }
    
    private func animate(
        layer: CALayer,
        appearance: Bool,
        progress: Float,
        completion: (() -> Void)? = nil
    ) {
        let opacity: CGFloat
        let fromScale: CGFloat
        let toScale: CGFloat
        if appearance {
            opacity = 1
            fromScale = (1 - .init(max(0.1, progress))) / 2
            toScale = 1
        } else {
            opacity = 0
            fromScale = .init(max(0.1, 1 - progress))
            toScale = 0.1
        }
        layer.removeAllAnimations()
        CATransaction.begin()
        CATransaction.setAnimationDuration(Constants.qrAnimationDuration * .init(1 - progress))
        CATransaction.setCompletionBlock(completion)
        layer.animate(opacity, forKeyPath: "opacity")
        layer.animate(NSValue(caTransform3D: CATransform3DMakeScale(toScale, toScale, 1)),
                      initialValue: NSValue(caTransform3D: CATransform3DMakeScale(fromScale, fromScale, 1)),
                      forKeyPath: "transform")
        CATransaction.commit()
    }
    
    private func qrRectPath(for rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        let side = max(rect.width, rect.height) / 4
        let radius = side / 5
        
        func createCorner(p1: CGPoint, p2: CGPoint, p3: CGPoint) {
            path.move(to: p1)
            path.addArc(tangent1End: p2, tangent2End: p3, radius: radius)
            path.addLine(to: p3)
        }
        createCorner(p1: .init(x: rect.minX, y: rect.minY + side),
                     p2: .init(x: rect.minX, y: rect.minY),
                     p3: .init(x: rect.minX + side, y: rect.minY))
        
        createCorner(p1: .init(x: rect.maxX - side, y: rect.minY),
                     p2: .init(x: rect.maxX, y: rect.minY),
                     p3: .init(x: rect.maxX, y: rect.minY + side))
        
        createCorner(p1: .init(x: rect.maxX, y: rect.maxY - side),
                     p2: .init(x: rect.maxX, y: rect.maxY),
                     p3: .init(x: rect.maxX - side, y: rect.maxY))
        
        createCorner(p1: .init(x: rect.minX + side, y: rect.maxY),
                     p2: .init(x: rect.minX, y: rect.maxY),
                     p3: .init(x: rect.minX, y: rect.maxY - side))
        return path
    }
}

extension AVCaptureDevice.DiscoverySession {
    var uniqueDevicePositionsCount: Int {
        Set(devices.map { $0.position }).count
    }
}
