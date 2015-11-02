//
//  RemoteViewController.swift
//  Actors
//
//  Created by Dario on 10/7/15.
//  Copyright © 2015 dario. All rights reserved.
//

import UIKit
import Theater
import AVFoundation


public class MonitorActor : ViewCtrlActor<MonitorViewController> {
    
    public required init(context: ActorSystem, ref: ActorRef) {
        super.init(context: context, ref: ref)
        let session : Optional<ActorRef> = AppActorSystem.shared.selectActor("RemoteCam Session")
        session! ! UICmd.AddMonitor(sender: ref)
    }
    
    override public func withCtrl(ctrl: MonitorViewController) -> Receive {
        return {[unowned self](msg : Message) in
            switch(msg) {
                
            case let cam as UICmd.ToggleCameraResp:
                self.setFlashMode(ctrl, flashMode:  cam.flashMode)
                
            case let flash as RemoteCmd.ToggleFlashResp:
                self.setFlashMode(ctrl, flashMode:  flash.flashMode)
                
                
            case is UICmd.UnbecomeMonitor:
                let session : Optional<ActorRef> = AppActorSystem.shared.selectActor("RemoteCam Session")
                session! ! msg
                
            case let f as RemoteCmd.OnFrame:
                if let img = UIImage(data: f.data) {
                    ^{ctrl.imageView.image = img}
                }
                
            default:
                self.receive(msg)
            }
        }
    }
    
    func setFlashMode(ctrl : MonitorViewController, flashMode : AVCaptureFlashMode?) {
        if let f = flashMode {
            switch(f) {
            case .Off:
                ^{ctrl.flashStatus.text = "Off"}
            case .On:
                ^{ctrl.flashStatus.text = "On"}
            case .Auto:
                ^{ctrl.flashStatus.text = "Auto"}
            }
        } else {
            ^{ctrl.flashStatus.text = "None"}
        }
    }
    
}

public class MonitorViewController : BaseViewController {
    
    let session = AppActorSystem.shared.selectActor("RemoteCam Session")!
    
    let monitor = AppActorSystem.shared.actorOf(MonitorActor.self, name: "MonitorActor")
    
    let timer : RCTimer = RCTimer()
    
    let soundManager : CPSoundManager = CPSoundManager()
    
    @IBOutlet weak var flashStatus: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var takePicture: UIButton!
    
    @IBOutlet weak var sliderContainer : UIView!
    
    @IBOutlet weak var timerSlider : UISlider!
    
    @IBOutlet weak var timerLabel: UILabel!
    
    @IBAction func toggleCamera(sender: UIButton) {
        session ! UICmd.ToggleCamera()
    }
    
    @IBAction func onSliderChange(sender: UISlider) {
        self.timerLabel.text = "\(Int(sender.value))"
    }
    @IBAction func toggleFlash(sender: UIButton) {
        session ! UICmd.ToggleFlash()
    }
    
    @IBAction func showSettings(sender: UIButton) {}
    
    @IBAction func showGallery(sender: UIButton) {}
    
    @IBAction func goBack(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func onTakePicture(sender: UIBarButtonItem) {
        
        func alertTitle(seconds : Int) -> String {
            return "Taking picture in \(seconds) seconds"
        }
        
        let alert = UIAlertController(title: alertTitle(Int(round(self.timerSlider.value))),
            message: nil,
            preferredStyle: .Alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            alert.dismissViewControllerAnimated(true, completion: nil)
            self.timer.cancel()
        })
        ^{self.soundManager.playBeepSound(CPSoundManagerAudioTypeSlow)}
        
        self.presentViewController(alert, animated: true) {[unowned self] () -> Void in
            self.timer.startTimerWithDuration(Int(round(self.timerSlider.value)), withTickHandler: {[unowned self](t) -> Void in
                ^{ alert.title = alertTitle(t.timeRemaining())}
                if t.timeRemaining() > 3 {
                    self.soundManager.playBeepSound(CPSoundManagerAudioTypeSlow)
                } else if t.timeRemaining() == 3 {
                    self.soundManager.playBeepSound(CPSoundManagerAudioTypeFast)
                }
                }, cancelHandler: {(t) -> Void in
                    ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                }, andCompletionHandler: {[unowned self] (t) -> Void in
                    ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                    self.session ! UICmd.TakePicture(sender: Optional.None)
                })
        }
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBarHidden = true
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        monitor ! SetViewCtrl(ctrl: self)
        self.configureTimerUI()
    }
    
    override public func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if self.isBeingDismissed() || self.isMovingFromParentViewController() {
            monitor ! UICmd.UnbecomeMonitor(sender: nil)
            monitor ! Actor.Harakiri(sender: nil)
        }
    }
    
    func configureTimerUI() {
        self.sliderContainer.layer.cornerRadius = 30.0
        self.sliderContainer.clipsToBounds=true

        let trans = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
        self.timerSlider.layer.anchorPoint = CGPointMake(1, 1)
        self.timerSlider.transform=trans
        let c = UIColor(red: 0.150, green: 0.670, blue: 0.80, alpha: 1)
        self.timerSlider.minimumTrackTintColor = c
        self.timerSlider.maximumTrackTintColor = UIColor(red: 0.060, green: 0.100, blue: 0.160, alpha: 1)
        self.timerSlider.thumbTintColor = c

//        RCRemoteConfiguration * remoteConfig=[[RCSession activeSession] remoteConfiguration];
//        _timerSlider.value=(float)remoteConfig.timer;
//        _timerLabel.text=[NSString stringWithFormat:@"%ld", (long)remoteConfig.timer];
    }
    
    deinit {
        self.timer.cancel()
        self.soundManager.stopPlayer()
    }
}