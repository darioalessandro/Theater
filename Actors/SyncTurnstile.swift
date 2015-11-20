//
//  Turnstile.swift
//  Actors
//
//  Created by Dario Lencina on 11/7/15.
//  Copyright © 2015 dario. All rights reserved.
//

import UIKit
import Theater

class CoinModule  : ViewCtrlActor<SyncTurnstileViewController> {
    
    required init(context: ActorSystem, ref: ActorRef) {
        super.init(context: context, ref : ref)
    }
    
    override func receiveWithCtrl(ctrl: SyncTurnstileViewController) -> Receive {
        return withMetalArm(ctrl.metalArm, ctrl: ctrl)
    }
    
    func withMetalArm(metalArm : ActorRef, ctrl: SyncTurnstileViewController) -> Receive {
        return { [unowned self](msg : Message) in
            switch(msg) {
            case is InsertCoin:
                metalArm ! MetalArm.Unlock(sender : self.this)
            default:
                self.receive(msg)
            }
        }
    }
    
}

class MetalArm : ViewCtrlActor<SyncTurnstileViewController> {
    
    class States {
        let locked = "locked"
        let unlocked = "unlocked"
    }
    
    var states = States()
    
    required init(context: ActorSystem, ref: ActorRef) {
        super.init(context: context, ref : ref)
    }
    
    override func receiveWithCtrl(ctrl: SyncTurnstileViewController) -> Receive {
        return locked(ctrl)
    }
    
    func locked(ctrl: SyncTurnstileViewController) -> Receive {
        ^{ctrl.status.text = "Turnstile is locked"}
        return {[unowned self] (msg : Message) in
            switch(msg) {
            case is Unlock:
                self.become(self.states.unlocked, state: self.unlocked(ctrl), discardOld:true)
            case is Push:
                self.showAlert("not opening", ctrl:  ctrl)
            default:
                self.receive(msg)
            }
        }
    }
    
    func unlocked(ctrl: SyncTurnstileViewController) -> Receive {
        ^{ctrl.status.text = "Turnstile is unlocked"}        
        return {[unowned self] (msg : Message) in
            switch(msg) {
            case is CoinModule.InsertCoin:
                self.showAlert("Already unlocked", ctrl:  ctrl)
            case is Push:
                self.showAlert("have a nice day!", ctrl:  ctrl)
                self.become(self.states.unlocked, state: self.locked(ctrl), discardOld:true)
            default:
                self.receive(msg)
            }
        }
    }
    
    func showAlert(message : String, ctrl : UIViewController) {
        ^{
            let alert = UIAlertController(title: message, message:"", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "ok", style: .Default, handler: nil))
            ctrl.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
}

class SyncTurnstileViewController : UIViewController {
    
    let coinModule : ActorRef = AppActorSystem.shared.actorOf(CoinModule.self, name : "CoinModule")
    
    let metalArm : ActorRef = AppActorSystem.shared.actorOf(MetalArm.self, name : "MetalArm")
    
    @IBOutlet weak var status: UILabel!
    
    @IBAction func onPush(sender: UIButton) {
        metalArm ! MetalArm.Push(sender : nil)
    }
    
    @IBAction func onInsertCoin(sender: UIButton) {
        coinModule ! CoinModule.InsertCoin(sender : nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        metalArm ! SetViewCtrl(ctrl:self)
        coinModule ! SetViewCtrl(ctrl:self)

    }
    
    override func viewDidDisappear(animated: Bool) {
        if self.isBeingDismissed() || self.isMovingFromParentViewController() {
            coinModule ! Actor.Harakiri(sender : nil)
            metalArm ! Actor.Harakiri(sender : nil)
        }
    }
    
    
}
