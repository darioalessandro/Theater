//
//  EnumExtensions.swift
//  Actors
//
//  Created by Dario Lencina on 11/3/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import AVFoundation
import Theater

extension AVCaptureDevicePosition {
    public func toggle() -> Try<AVCaptureDevicePosition> {
        switch(self) {
        case .Back:
            return Success(value: .Front)
        case .Front:
            return Success(value: .Back)
        default:
            return Failure(error: NSError(domain: "Unable to find camera position", code: 0, userInfo: nil))
        }
    }
}

extension AVCaptureFlashMode {
    public func next() -> AVCaptureFlashMode {
        switch(self) {
        case .Off:
            return .On
        case .On:
            return .Auto
        case .Auto:
            return .Off
        }
    }
}