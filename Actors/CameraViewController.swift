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
    
    let _sampleQueue : dispatch_queue_t = dispatch_queue_create("VideoSampleQueue", DISPATCH_QUEUE_SERIAL);
    
    lazy var remoteCamSession : ActorRef = AppActorSystem.shared.selectActor("RemoteCam Session")!
    
    
    public override init() {
        super.init()
        self.setSampleBufferDelegate(self, queue: _sampleQueue)
    }
    
    func imageFromSampleBuffer(sampleBuffer : CMSampleBufferRef) -> UIImage {
        let cvImage = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        let cropRect = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(320, 320),
            CGRectMake(0,0, CGFloat(CVPixelBufferGetWidth(cvImage!)),CGFloat(CVPixelBufferGetHeight(cvImage!))));
        
        let ciImage = CIImage(CVImageBuffer: cvImage!, options: nil)
        
        let croppedImage = ciImage.imageByCroppingToRect(cropRect)
        
        let scaleFilter = CIFilter(name: "CILanczosScaleTransform")
        scaleFilter?.setValue(croppedImage, forKey: "inputImage")
        scaleFilter?.setValue(Float(0.25), forKey: "inputScale")
        scaleFilter?.setValue(Float(1.0), forKey: "inputAspectRatio")
        let finalImage : CIImage = scaleFilter?.valueForKey("outputImage") as! CIImage
        let cgBackedImage = self.cgImageBackedImageWithCIImage(finalImage)
        
        return cgBackedImage
    }
    
    
    public func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {

        let cgBackedImage = self.imageFromSampleBuffer(sampleBuffer)
        let imageData = UIImageJPEGRepresentation(cgBackedImage, 0.1)!
        remoteCamSession ! SendFrame(data: imageData, sender: Optional.None)
    }
    
    func cgImageBackedImageWithCIImage(ciImage : CIImage) -> UIImage  {
        let  context = CIContext(options: Optional.None)
        let ref = context.createCGImage(ciImage, fromRect: ciImage.extent)
        let image = UIImage(CGImage: ref, scale: UIScreen.mainScreen().scale, orientation:.Right)
        return image;
    }
}

public class CameraViewController : UIViewController {
    
    var captureSession : Optional<AVCaptureSession> = Optional.None;

    let output : ActorOutput = ActorOutput()
    
    lazy var remoteCamSession : ActorRef = AppActorSystem.shared.actorOf(RemoteCamSession.self, name: "RemoteCam Session")
    
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.setupCamera()
    }
    
    func setupCamera() -> Void {
        captureSession = AVCaptureSession()
        
        // Setup the preview view
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