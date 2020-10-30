//
//  PreviewView.swift
//  Store
//
//  Created by Philip Dukhov on 10/30/20.
//

import UIKit
import AVFoundation

class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    
    // swiftlint:disable:next force_cast
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    
    var session: AVCaptureSession? {
        get { videoPreviewLayer.session }
        set { videoPreviewLayer.session = newValue }
    }
}
