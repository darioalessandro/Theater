//
//  RemoteViewController.swift
//  Actors
//
//  Created by Dario on 10/7/15.
//  Copyright © 2015 dario. All rights reserved.
//

import UIKit
import Theater

public class AddMonitor : Message {
    
}

public class AddImageView : Message {
    let imageView : UIImageView
    
    public required init(imageView : UIImageView) {
        self.imageView = imageView
        super.init(sender: Optional.None)
    }
}

public class MonitorActor : Actor {
    
    weak var imageView : Optional<UIImageView> = Optional.None
    
    public required init(context: ActorSystem, ref: ActorRef) {
        super.init(context: context, ref: ref)
        let session : Optional<ActorRef> = AppActorSystem.shared.selectActor("RemoteCam Session")
        session! ! AddMonitor(sender: ref)
    }
    
    override public func receive(msg: Message) {
        switch(msg) {
            
            case let i as AddImageView:
                self.imageView = i.imageView
                break
            
            case is UnbecomeMonitor:
                let session : Optional<ActorRef> = AppActorSystem.shared.selectActor("RemoteCam Session")
                session! ! msg
                break
            
            case let f as OnFrame:
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


public class RemoteViewController : UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    let monitor = AppActorSystem.shared.actorOf(MonitorActor.self, name: "MonitorActor")
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        monitor ! AddImageView(imageView: self.imageView)
    }
    
    override public func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if(self.isBeingDismissed() || self.isMovingFromParentViewController()){
            monitor ! UnbecomeMonitor(sender: Optional.None)
        }
    }
}