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
        let msg = RemoteCmd.SendFrame(data: imageData, sender: Optional.None, fps:3)
        remoteCamSession ! msg
    }
}

public class CameraViewController : UIViewController {
    
    var captureSession : Optional<AVCaptureSession> = Optional.None;

    let output : ActorOutput = ActorOutput()
    
    var captureVideoPreviewLayer : AVCaptureVideoPreviewLayer!
    
    @IBOutlet weak var back : UIButton!
    
    let stillImageOutput = AVCaptureStillImageOutput()
    
    var session : ActorRef = AppActorSystem.shared.selectActor("RemoteCam Session")!
    
    let fps = 3
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.setupCamera()
        session ! UICmd.AddCameraController(sender: Optional.None, ctrl: self)
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBarHidden = true
    }
    
    override public func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if self.isBeingDismissed() || self.isMovingFromParentViewController() {
            if let cs = captureSession {
                cs.stopRunning()
                session ! UICmd.UnbecomeCamera(sender : Optional.None)
            }
        }
    }
    
    private func nextFlashMode(mode : AVCaptureFlashMode) -> AVCaptureFlashMode {
        switch(mode) {
            case .Off:
                return .On
            case .On:
                return .Auto
            case .Auto:
                return .Off
        }
    }
    
    func toggleCamera() -> Try<(AVCaptureFlashMode,AVCaptureDevicePosition)> {
        do {
            if let captureSession = self.captureSession,
                let genericDevice = captureSession.inputs.first as? AVCaptureDeviceInput,
                let device = genericDevice.device {
                    switch(device.position) {
                    case .Back:
                        let front = try AVCaptureDeviceInput(device: self.cameraForPosition(.Front))
                        captureSession.removeInput(genericDevice)
                        captureSession.addInput(front)
                        return Success(value: (front.device.flashMode, front.device.position))
                    case .Front:
                        let back = try AVCaptureDeviceInput(device: self.cameraForPosition(.Back))
                        captureSession.removeInput(genericDevice)
                        captureSession.addInput(back)
                        return Success(value: (back.device.flashMode, back.device.position))
                    default:
                        return Failure(error: NSError(domain: "Unable to find camera position", code: 0, userInfo: nil))
                    }
                    
            } else {
                return Failure(error: NSError(domain: "Unable to find camera", code: 0, userInfo: nil))
            }
        } catch let error as NSError {
            print("error \(error)")
            return Failure(error: error)
        }
    }
    
    func toggleFlash() -> Try<AVCaptureFlashMode> {
        if let captureSession = self.captureSession,
           let genericDevice = captureSession.inputs.first,
           let device = genericDevice as? AVCaptureDevice {
            return self.setFlashMode(nextFlashMode(device.flashMode), device: device)
        }  else {
            return Failure(error: NSError(domain: "Unable to find camera", code: 0, userInfo: nil))
        }
    }
    
    func setFlashMode(mode : AVCaptureFlashMode, device : AVCaptureDevice) -> Try<AVCaptureFlashMode> {
        if device.hasFlash {
            do {
                try device.lockForConfiguration()
                device.flashMode = mode
                device.unlockForConfiguration()
            } catch let error as NSError {
                print("error \(error)")
                return Failure(error: error)
            } catch {
                print("sdfsdf")
               return Failure(error: NSError(domain: "Unknown error", code: 0, userInfo: nil))
            }
        }
    
        return Success(value: mode)
    }
    
    func cameraForPosition(position : AVCaptureDevicePosition) -> AVCaptureDevice {
        let videoDevices : [AVCaptureDevice] = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as! [AVCaptureDevice] //stupid swift
        let filtered : [AVCaptureDevice] = videoDevices.filter { return $0.position == position}
        if let cam = filtered.first {
            return cam
        } else {
            return AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        }
    }
    
    func setupCamera() -> Void {
        if let cs = self.captureSession {
            cs.stopRunning()
        }
        captureSession = AVCaptureSession()
        captureSession!.sessionPreset = AVCaptureSessionPresetHigh
        
        self.captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        captureVideoPreviewLayer.frame = self.view.frame

        self.view.layer.insertSublayer(captureVideoPreviewLayer, below: self.back.layer)
        
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
                
                self.setFrameRate(self.fps,videoDevice:videoDevice)
                                
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
    
    @IBAction func goBack(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    public override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        self.rotateCameraToOrientation(toInterfaceOrientation)
    }
    
    private func rotateCameraToOrientation( orientation : UIInterfaceOrientation) {
        let o = OrientationUtils.transform(orientation)
        self.captureVideoPreviewLayer.connection.videoOrientation = o
        if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo) {
            videoConnection.videoOrientation = o
            self.captureVideoPreviewLayer.frame = self.view.bounds
        }
        
        self.stillImageOutput.connections.forEach {
            ($0 as! AVCaptureConnection).videoOrientation = o //stupid swift
        }
    
    }
    
    func takePicture() -> Void {
        if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo) {
            stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection) {[unowned self]
                (imageSampleBuffer, error) in
                if imageSampleBuffer == nil {
                    self.session ! UICmd.OnPicture(sender: Optional.None, error: NSError(domain: "Unable to take picture", code: 0, userInfo: nil))
                } else {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer)
                    self.session ! UICmd.OnPicture(sender: Optional.None, pic:imageData)
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