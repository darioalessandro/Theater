    //
//  CameraViewController.swift
//  Actors
//
//  Created by Dario on 10/7/15.
//  Copyright © 2015 dario. All rights reserved.
//

import UIKit
import Theater
import AVFoundation
    
    
public class ActorOutput : AVCaptureVideoDataOutput, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let videoQueue : dispatch_queue_t = dispatch_queue_create("VideoQueue", DISPATCH_QUEUE_SERIAL);
    
    lazy var remoteCamSession : ActorRef = AppActorSystem.shared.selectActor("RemoteCam Session")!
    
    public override init() {
        super.init()
        self.setSampleBufferDelegate(self, queue: videoQueue)
    }
    
    public func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        let cgBackedImage = UIImage(fromSampleBuffer: sampleBuffer)
        let imageData = UIImageJPEGRepresentation(cgBackedImage, 0.1)!
        remoteCamSession ! SendFrame(data: imageData, sender: Optional.None)
    }

    
    deinit {
        
    }
}

public class CameraViewController : UIViewController {
    
    var captureSession : Optional<AVCaptureSession> = Optional.None;

    let output : ActorOutput = ActorOutput()
    
    lazy var remoteCamSession : ActorRef = AppActorSystem.shared.selectActor("RemoteCam Session")!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.setupCamera()
    }
    
    override public func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if(self.isBeingDismissed() || self.isMovingFromParentViewController()){
            captureSession?.stopRunning()
            remoteCamSession ! UnbecomeCamera(sender : Optional.None)
        }
    }
    
    func setupCamera() -> Void {
        captureSession = AVCaptureSession()
        
        let captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        captureVideoPreviewLayer.frame = CGRectMake(0,0, 320, 320);

        self.view.layer.addSublayer(captureVideoPreviewLayer)
        
        if let videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo),
            captureSession = captureSession {
            do {
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                captureSession.addInput(videoDeviceInput)
                
                captureSession.addOutput(output)
                
                output.videoSettings = [kCVPixelBufferPixelFormatTypeKey : Int(kCVPixelFormatType_32BGRA)]
                output.alwaysDiscardsLateVideoFrames = true
                
                self.setFrameRate(10,videoDevice:videoDevice)
                                
                self.captureSession?.startRunning()
            } catch let error as NSError {
                print("error \(error)")
            } catch {
                print("sdfsdf")
            }
        } else {
            print("error")
        }
    }
    
    func setFrameRate(framerate:Int, videoDevice: AVCaptureDevice) -> Void {
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1,Int32(framerate))
            videoDevice.activeVideoMinFrameDuration = CMTimeMake(1,Int32(framerate))
            videoDevice.unlockForConfiguration()
        } catch let error as NSError {
            print("error \(error)")
        } catch {
            print("sdfsdf")
        }
    }
}