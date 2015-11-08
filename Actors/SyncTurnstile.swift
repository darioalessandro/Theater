//
//  Turnstile.swift
//  Actors
//
//  Created by Dario Lencina on 11/7/15.
//  Copyright © 2015 dario. All rights reserved.
//

import UIKit
import Theater

class SyncTurnstileActor : ViewCtrlActor<SyncTurnstileViewController> {
    
    class States {
        let locked = "locked"
        let unlocked = "unlocked"
    }
    
    var states = States()
    
    required init(context: ActorSystem, ref: ActorRef) {
        super.init(context: context, ref : ref)
    }
    
    override func withCtrl(ctrl: SyncTurnstileViewController) -> Receive {
        
        return {[unowned self] (msg : Message) in
            switch(msg) {
                case is PowerUp:
                    self.become(self.states.locked, state: self.locked(ctrl))
    
                default:
                    self.showAlert("not powered", ctrl: ctrl)
            }
        }
    }
    
    func locked(ctrl: SyncTurnstileViewController) -> Receive {
        ^{ctrl.status.text = "Turnstile is locked"}
        return {[unowned self] (msg : Message) in
            switch(msg) {
            case is Coin:
                self.become(self.states.unlocked, state: self.unlocked(ctrl))
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
            case is Coin:
                self.showAlert("thanks, not doing anything", ctrl:  ctrl)
            case is Push:
                self.showAlert("have a nice day!", ctrl:  ctrl)
                self.become(self.states.locked, state: self.locked(ctrl))
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
    
    let turnstileActor : ActorRef = AppActorSystem.shared.actorOf(SyncTurnstileActor.self, name : "SyncTurnstileActor")
    
    @IBOutlet weak var status: UILabel!
    
    @IBAction func onPush(sender: UIButton) {
        turnstileActor ! SyncTurnstileActor.Push(sender : nil)
    }
    
    @IBAction func onInsertCoin(sender: UIButton) {
        turnstileActor ! SyncTurnstileActor.Coin(sender : nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        turnstileActor ! SetViewCtrl(ctrl:self)
        turnstileActor ! SyncTurnstileActor.PowerUp(sender : nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        if self.isBeingDismissed() || self.isMovingFromParentViewController() {
            turnstileActor ! Actor.Harakiri(sender : nil)
        }
    }
    
    
}
