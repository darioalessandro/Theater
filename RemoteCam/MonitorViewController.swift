//
//  RemoteViewController.swift
//  Actors
//
//  Created by Dario on 10/7/15.
//  Copyright © 2015 dario. All rights reserved.
//

import UIKit
import Theater


public class MonitorActor : Actor {
    
    weak var imageView : Optional<UIImageView> = Optional.None
    
    public required init(context: ActorSystem, ref: ActorRef) {
        super.init(context: context, ref: ref)
        let session : Optional<ActorRef> = AppActorSystem.shared.selectActor("RemoteCam Session")
        session! ! UICmd.AddMonitor(sender: ref)
    }
    
    override public func receive(msg: Actor.Message) {
        switch(msg) {
            
            case let i as UICmd.AddImageView:
                self.imageView = i.imageView
                break
            
            case is UICmd.UnbecomeMonitor:
                let session : Optional<ActorRef> = AppActorSystem.shared.selectActor("RemoteCam Session")
                session! ! msg
                break
            
            case let f as RemoteCmd.OnFrame:
                let img = UIImage(data: f.data)
                ^{
                    if let imageView = self.imageView {
                        imageView.image = img
                    }
                }
                break
            
            default:
                super.receive(msg)
            
        }
    }
}

public class MonitorViewController : UIViewController {
    
    let session = AppActorSystem.shared.selectActor("RemoteCam Session")!
    
    let monitor = AppActorSystem.shared.actorOf(MonitorActor.self, name: "MonitorActor")
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var takePicture: UIButton!
    
    @IBAction func onTakePicture(sender: UIBarButtonItem) {
        session ! UICmd.TakePicture(sender: Optional.None)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.toolbarHidden = false
        monitor ! UICmd.AddImageView(imageView: self.imageView)
    }
    
    override public func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if(self.isBeingDismissed() || self.isMovingFromParentViewController()){
                    self.navigationController?.toolbarHidden = true
            monitor ! UICmd.UnbecomeMonitor(sender: Optional.None)
        }
    }
}