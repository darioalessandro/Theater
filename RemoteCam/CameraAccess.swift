//
//  CameraAccess.swift
//  Actors
//
//  Created by Dario Lencina on 11/2/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Photos
import AVFoundation
import Theater

extension UIViewController {
    
    @objc public func verifyCameraAndCameraRollAccess() {
        verifyCameraRollAccess()
        verifyCameraAccess()
    }
    
    public func verifyCameraAccess() {
        if AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) != .Authorized {
            AVCaptureDevice.requestAccessForMediaType( AVMediaTypeVideo) {
                if !$0 {
                    ^{self.showNoAccessToCamera()}
                }
            }
        }
    }
    
    public func verifyCameraRollAccess() {
        if PHPhotoLibrary.authorizationStatus() != .Authorized {
            PHPhotoLibrary.requestAuthorization {
                if $0 != .Authorized {
                    ^{self.showNoCameraRollAccess()}
                }
            }
        }
    }
    
    public func showNoAccessToCamera() {
        let fileName = "BFDeniedAccessToCameraView"
        let blocker = NSBundle.mainBundle().loadNibNamed(fileName, owner: nil, options: nil)[0] as! UIView
        self.addErrorView(blocker)
    }
    
    public func addErrorView(view : UIView) {
            if let delegate = UIApplication.sharedApplication().delegate,
            window = delegate.window {
                window!.addSubview(view)
                view.frame = (window?.bounds)!
            }
    }
    
    public func showNoCameraRollAccess() {
        let fileName = "BFDeniedAccessToAssetsView"
        let blocker = NSBundle.mainBundle().loadNibNamed(fileName, owner: nil, options: nil)[0] as! UIView
        addErrorView(blocker)
    }
}