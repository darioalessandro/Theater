//
//  GreetingActor.swift
//  Actors
//
//  Created by Dario Lencina on 11/9/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Theater

class Greeting : Actor.Message {}
class Angry : Actor.Message {}
class Happy : Actor.Message {}

class GreetingActor: ViewCtrlActor<GreetingActorController> {
    
    required init(context: ActorSystem, ref: ActorRef) {
        super.init(context: context, ref: ref)
    }
    
    override func receiveWithCtrl(ctrl: GreetingActorController) -> Receive {
        return self.happy(ctrl)
    }
    
    func happy(ctrl: GreetingActorController) -> Receive { return {[unowned self](msg : Message) in
            switch(msg) {
            case is Greeting:
                ^{ctrl.say("Hello")}
                
            case is Angry:
                ^{ctrl.title = "Actor is Angry"
                    ctrl.rotateMouthToAngry()
                }
                self.become("angry", state: self.angry(ctrl), discardOld: true)
            
            default:
                self.receive(msg)
            }
        }
    }
    
    func angry(ctrl: GreetingActorController)  -> Receive { return {[unowned self](msg : Message) in
            switch(msg) {
            case is Greeting:
                ^{ctrl.say("Go away ")}
                
            case is Happy:
                ^{ctrl.title = "Actor is Happy"
                    ctrl.rotateMouthToHappy()
                }
                self.become("happy", state: self.happy(ctrl), discardOld: true)
                
            default:
                self.receive(msg)
            }
        }
    }
    
}

class GreetingActorController : UIViewController {
    
    let greetingActor = AppActorSystem.shared.actorOf(GreetingActor.self)
    
    @IBOutlet weak var mouth : UIImageView!
    
    @IBAction func sayHi() {
        greetingActor ! Greeting(sender: nil)
    }
    
    @IBAction func sendAngry() {
        greetingActor ! Angry(sender: nil)
    }
    
    @IBAction func sendHappy() {
        greetingActor ! Happy(sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        greetingActor ! SetViewCtrl(ctrl: self)
        greetingActor ! Angry(sender: nil)
        self.navigationController?.toolbarHidden = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        if self.isBeingDismissed() || self.isMovingFromParentViewController() {
            greetingActor ! Actor.Harakiri(sender: nil)
            self.navigationController?.toolbarHidden = true
        }
    }
    
    func say(msg : String) {
        let alert : UIAlertController = UIAlertController(title: "Actor says:", message: msg, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true,completion: nil)
    }
    
    func rotateMouthToAngry() {
        UIView.animateWithDuration(0.3, animations: {
            self.mouth.transform = CGAffineTransformIdentity
            }, completion: nil)
    }
    
    func rotateMouthToHappy() {
        UIView.animateWithDuration(0.3, animations: {
            self.mouth.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
        }, completion: nil)
        
    }
    
    
}