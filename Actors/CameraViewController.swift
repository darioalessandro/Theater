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
        let msg = SendFrame(data: imageData, sender: Optional.None, fps:3)        
        remoteCamSession ! msg
    }

    
    deinit {
        
    }
}

public class CameraViewController : UIViewController {
    
    var captureSession : Optional<AVCaptureSession> = Optional.None;

    let output : ActorOutput = ActorOutput()
    
    var captureVideoPreviewLayer : AVCaptureVideoPreviewLayer!
    
    let stillImageOutput = AVCaptureStillImageOutput()
    
    var session : ActorRef = AppActorSystem.shared.selectActor("RemoteCam Session")!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.setupCamera()
        session ! AddCameraController(sender: Optional.None, ctrl: self)
    }
    
    override public func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if(self.isBeingDismissed() || self.isMovingFromParentViewController()){
            captureSession?.stopRunning()
            session ! UnbecomeCamera(sender : Optional.None)
        }
    }
    
    func setupCamera() -> Void {
        if let captureSession = self.captureSession {
            captureSession.stopRunning()
        }
        captureSession = AVCaptureSession()
        captureSession!.sessionPreset = AVCaptureSessionPresetHigh
        
        self.captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        captureVideoPreviewLayer.frame = self.view.frame

        self.view.layer.addSublayer(captureVideoPreviewLayer)
        
        stillImageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
        
        if captureSession!.canAddOutput(stillImageOutput) {
            captureSession!.addOutput(stillImageOutput)
        }else {
            print("did not setup output")
        }
        
        if let videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo),
            captureSession = captureSession {
            do {
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                captureSession.addInput(videoDeviceInput)
                
                captureSession.addOutput(output)
                
                output.videoSettings = [kCVPixelBufferPixelFormatTypeKey : Int(kCVPixelFormatType_32BGRA)]
                output.alwaysDiscardsLateVideoFrames = true
                
                self.setFrameRate(3,videoDevice:videoDevice)
                                
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
    
    func takePicture() -> Void {
        if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo) {
            stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection) {
                (imageDataSampleBuffer, error) -> Void in
                if imageDataSampleBuffer == nil {
                    self.session ! RemoteCmd.TakePicResp(sender: Optional.None, error: NSError(domain: "Unable to take picture", code: 0, userInfo: nil))
                } else {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    self.session ! RemoteCmd.TakePicAck()
                    self.session ! RemoteCmd.TakePicResp(sender: Optional.None, pic:imageData)
                }
            }
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