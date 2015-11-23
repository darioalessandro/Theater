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
    
    let audioPlayer : ActorRef
    
    required init(context: ActorSystem, ref: ActorRef) {
        self.audioPlayer = context.actorOf(AudioPlayer.self)
        super.init(context: context, ref : ref)
    }
    
    override func receiveWithCtrl(ctrl: SyncTurnstileViewController) -> Receive {
        return withGate(ctrl.gate, ctrl: ctrl)
    }
    
    func withGate(gate : ActorRef, ctrl: SyncTurnstileViewController) -> Receive {
        return { [unowned self](msg : Message) in
            switch(msg) {
            case is InsertCoin:
                self.audioPlayer ! AudioPlayer.PlaySound(sender: self.this, name: "coin", ext: "mp3")
                NSThread.sleepForTimeInterval(0.5)
                gate ! Gate.Unlock(sender : self.this)
            default:
                self.receive(msg)
            }
        }
    }
    
    deinit {
        self.audioPlayer ! Harakiri(sender: self.this)
    }
    
}

class Gate : ViewCtrlActor<SyncTurnstileViewController> {
    
    class States {
        let locked = "locked"
        let unlocked = "unlocked"
    }
    
    var states = States()
    
    let audioPlayer : ActorRef
    
    required init(context: ActorSystem, ref: ActorRef) {
        self.audioPlayer = context.actorOf(AudioPlayer.self)
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
                self.become(self.states.unlocked, state: self.unlocked(ctrl, fares: 1), discardOld:true)
            case is Push:
                self.audioPlayer ! AudioPlayer.PlaySound(sender: self.this, name: "locked", ext: "mp3")
            default:
                self.receive(msg)
            }
        }
    }
    
    func unlocked(ctrl: SyncTurnstileViewController, fares : UInt) -> Receive {
        ^{ctrl.status.text = "Turnstile is unlocked, fares = \(fares)"}
        return {[unowned self] (msg : Message) in
            switch(msg) {
            case is Unlock:
                self.become(self.states.unlocked, state: self.unlocked(ctrl, fares: fares + 1), discardOld:true)
            case is Push:
                self.audioPlayer ! AudioPlayer.PlaySound(sender: self.this, name: "turnstile", ext: "mp3")
                if fares == 1 {
                    self.become(self.states.locked, state: self.locked(ctrl), discardOld:true)
                } else {
                    self.become(self.states.unlocked, state: self.unlocked(ctrl, fares: fares - 1), discardOld:true)
                }
            default:
                self.receive(msg)
            }
        }
    }
    
    deinit {
        self.audioPlayer ! Harakiri(sender: self.this)
    }
    
}

class SyncTurnstileViewController : UIViewController {
    
    let coinModule : ActorRef = AppActorSystem.shared.actorOf(CoinModule.self)
    
    let gate : ActorRef = AppActorSystem.shared.actorOf(Gate.self)
    
    @IBOutlet weak var status: UILabel!
    
    @IBAction func onPush(sender: UIButton) {
        gate ! Gate.Push(sender : nil)
    }
    
    @IBAction func onInsertCoin(sender: UIButton) {
        coinModule ! CoinModule.InsertCoin(sender : nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gate ! SetViewCtrl(ctrl:self)
        coinModule ! SetViewCtrl(ctrl:self)
    }
    
    override func viewDidDisappear(animated: Bool) {
        if self.isBeingDismissed() || self.isMovingFromParentViewController() {
            coinModule ! Actor.Harakiri(sender : nil)
            gate ! Actor.Harakiri(sender : nil)
        }
    }
    
    
}
