//
//  AVCaptureDevice.DiscoverySession+uniqueDevicePositionsCount.swift
//  Store
//
//  Created by Philip Dukhov on 10/31/20.
//

import AVFoundation

extension AVCaptureDevice.DiscoverySession {
    var uniqueDevicePositionsCount: Int {
        Set(devices.map { $0.position }).count
    }
}
