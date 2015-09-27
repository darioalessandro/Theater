//
//  ViewController.swift
//  Actors
//
//  Created by Dario Lencina on 9/26/15.
//  Copyright © 2015 dario. All rights reserved.
//

import UIKit
import Theater

class SetController: Message {
    
    let ctrl : ViewController
    
    init(ctrl : ViewController) {
        self.ctrl = ctrl
        super.init(sender : Optional.None)
    }
}

public class ReactiveViewController : Actor {
    
    var ctrl : Optional<ViewController> = Optional.None
    
    private func addListeners(ctrl : ViewController) -> Void {
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            ctrl.label.text = "changed text from actor"
            ctrl.button.addTarget(self, action: "onClick:", forControlEvents: .TouchUpInside)
        }
    }
    
    @objc func onClick(sender : UIButton!) {
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.ctrl!.label.text = "changed: \(NSDate.init())"
        }
    }
    
    required public init(context : ActorSystem, ref : ActorRef) {
        super.init(context: context, ref: ref)
    }
    
    override public func receive(msg: Message) {
        switch(msg) {
        case is SetController :
            let w : SetController = msg as! SetController
            self.ctrl = w.ctrl
            print("set ctrl \(self.ctrl)")
            self.addListeners(self.ctrl!)
            break;
            
        default:
            super.receive(msg)
            
        }
    }
}


class ViewController : UIViewController {
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var label: UILabel!
    
    var reactiveViewController : ActorRef =
    ActorRef(context: AppActorSystem.shared, path: ActorPath(path: ""))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.reactiveViewController =
            AppActorSystem.shared.actorOf(ReactiveViewController.self, name : "reactiveViewController")
        
        self.reactiveViewController ! SetController(ctrl: self)
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

