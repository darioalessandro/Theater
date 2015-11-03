//
//  OrientationUtils.swift
//  Actors
//
//  Created by Dario Lencina on 11/1/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import AVFoundation

public class OrientationUtils {
    
    class public func transform(o : UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch(o) {
            
        case .LandscapeLeft:
            return .LandscapeLeft
            
        case .LandscapeRight:
            return .LandscapeRight
            
        case .PortraitUpsideDown:
            return .PortraitUpsideDown
            
        default:
            return .Portrait;
        }
    }
    
    class public func transformToUIKit(o : AVCaptureVideoOrientation) ->  UIInterfaceOrientation{
        switch(o) {
            
        case .LandscapeLeft:
            return .LandscapeLeft
            
        case .LandscapeRight:
            return .LandscapeRight
            
        case .PortraitUpsideDown:
            return .PortraitUpsideDown
            
        default:
            return .Portrait;
        }
    }
    
    class public func transformToUIImage(o : AVCaptureVideoOrientation) ->  UIImageOrientation {
        switch(o) {
            
        case .LandscapeLeft:
            return .Left
            
        case .LandscapeRight:
            return .Right
            
        case .PortraitUpsideDown:
            return .Down
            
        default:
            return .Up;
        }
    }
    
    class public func transformOrientationToImage(o : UIInterfaceOrientation) -> UIImageOrientation {
        switch(o) {
            
        case .LandscapeLeft:
            return .Left
            
        case .LandscapeRight:
            return .Right
            
        case .PortraitUpsideDown:
            return .Down
            
        default:
            return .Up
        }
    }
}