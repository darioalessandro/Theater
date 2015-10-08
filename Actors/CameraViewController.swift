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

public class CameraViewController : UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var captureSession : Optional<AVCaptureSession> = Optional.None;

    
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
        
        // Create video device input
        
        if let videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo),
            captureSession = captureSession {
            do {
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                captureSession.addInput(videoDeviceInput)
                
                
                let multipeerVideoOutput = self as! AVCaptureOutput
                                
                captureSession.addOutput(multipeerVideoOutput)
                
                self.setFrameRate(15,videoDevice:videoDevice)
                
               // [self setFrameRate:15 onDevice:videoDevice];
                
                //[_captureSession startRunning];
            } catch let error as NSError {
                print("error \(error)")
            } catch {
                print("sdfsdf")
            }
        } else {
            print("error")
            /*UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"No video device" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];*/
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

    
    func cgImageBackedImageWithCIImage(ciImage : CIImage) -> UIImage  {
        let  context = CIContext(options: Optional.None)
        let ref = context.createCGImage(ciImage, fromRect: ciImage.extent)
        let image = UIImage(CGImage: ref, scale: UIScreen.mainScreen().scale, orientation:.Right)
        return image;
    }
    
    /*
    
    - (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if (_session.connectedPeers.count) {
    NSNumber* timestamp = @(CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)));
    
    CVImageBufferRef cvImage = CMSampleBufferGetImageBuffer(sampleBuffer);
    CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(320, 320), CGRectMake(0,0, CVPixelBufferGetWidth(cvImage),CVPixelBufferGetHeight(cvImage)) );
    CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:cvImage];
    CIImage* croppedImage = [ciImage imageByCroppingToRect:cropRect];
    
    CIFilter *scaleFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
    [scaleFilter setValue:croppedImage forKey:@"inputImage"];
    [scaleFilter setValue:[NSNumber numberWithFloat:0.25] forKey:@"inputScale"];
    [scaleFilter setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputAspectRatio"];
    CIImage *finalImage = [scaleFilter valueForKey:@"outputImage"];
    UIImage* cgBackedImage = [self cgImageBackedImageWithCIImage:finalImage];
    
    NSData *imageData = UIImageJPEGRepresentation(cgBackedImage, 0.2);
    
    // maybe not always the correct input?  just using this to send current FPS...
    AVCaptureInputPort* inputPort = connection.inputPorts[0];
    AVCaptureDeviceInput* deviceInput = (AVCaptureDeviceInput*) inputPort.input;
    CMTime frameDuration = deviceInput.device.activeVideoMaxFrameDuration;
    NSDictionary* dict = @{
    @"image": imageData,
    @"timestamp" : timestamp,
    @"framesPerSecond": @(frameDuration.timescale)
    };
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict];
    
    
    [_session sendData:data toPeers:_session.connectedPeers withMode:MCSessionSendDataReliable error:nil];
    }
    }
    */

}