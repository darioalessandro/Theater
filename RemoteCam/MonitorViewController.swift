//
//  RemoteViewController.swift
//  Actors
//
//  Created by Dario on 10/7/15.
//  Copyright © 2015 dario. All rights reserved.
//

import UIKit
import Theater


public class MonitorActor : ViewCtrlActor<MonitorViewController> {
    
    public required init(context: ActorSystem, ref: ActorRef) {
        super.init(context: context, ref: ref)
        let session : Optional<ActorRef> = AppActorSystem.shared.selectActor("RemoteCam Session")
        session! ! UICmd.AddMonitor(sender: ref)
    }
    
    override public func withCtrl(ctrl: MonitorViewController) -> Receive {
        return {[unowned self](msg : Message) in
            switch(msg) {
                
            case let flash as RemoteCmd.ToggleFlashResp:
                if let f = flash.flashMode {
                    switch(f) {
                    case .Off:
                        ^{ctrl.flashStatus.text = "Off"}
                    case .On:
                        ^{ctrl.flashStatus.text = "On"}
                    case .Auto:
                        ^{ctrl.flashStatus.text = "Auto"}
                    default:
                        ^{ctrl.flashStatus.text = "--"}
                    }
                    
                }
                
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
    
}

public class MonitorViewController : UIViewController {
    
    let session = AppActorSystem.shared.selectActor("RemoteCam Session")!
    
    let monitor = AppActorSystem.shared.actorOf(MonitorActor.self, name: "MonitorActor")
    
    @IBOutlet weak var flashStatus: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var takePicture: UIButton!
    
    @IBOutlet weak var sliderContainer : UIView!
    
    @IBOutlet weak var timerSlider : UISlider!
    
    @IBAction func toggleCamera(sender: UIButton) {
        session ! UICmd.ToggleCamera()
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
        session ! UICmd.TakePicture(sender: Optional.None)
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
        self.timerSlider.minimumTrackTintColor = UIColor(red: 0.060, green: 0.100, blue: 0.160, alpha: 1)
        self.timerSlider.thumbTintColor = c

//        RCRemoteConfiguration * remoteConfig=[[RCSession activeSession] remoteConfiguration];
//        _timerSlider.value=(float)remoteConfig.timer;
//        _timerLabel.text=[NSString stringWithFormat:@"%ld", (long)remoteConfig.timer];
    }
}