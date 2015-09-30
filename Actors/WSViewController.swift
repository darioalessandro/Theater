//
//  WSViewController.swift
//  Actors
//
//  Created by Dario Lencina on 9/29/15.
//  Copyright © 2015 dario. All rights reserved.
//

import UIKit
import Theater

public class WSRViewControler : Actor {
    
    let wsClient : ActorRef
    
    public required init(context: ActorSystem, ref: ActorRef) {
        self.wsClient = context.actorOf(WebSocketClient)
        super.init(context: context, ref: ref)
    }

    override public func receive(msg: Message) {
        switch(msg) {
        case is Connect:
            let w = msg as! Connect
            wsClient ! Connect(url: w.url, delegate: this)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(5 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                self.wsClient ! SendMessage(sender: self.this, message: "Hi")
            })
            break;
        case is OnConnect:
            print("web socket is connected")
            break;
            
        case is OnMessage:
            let w = msg as! OnMessage
            print("got message \(w.message)")
            break;
            
        default:
            super.receive(msg)
        }
        
    }
    
}

class WSViewController : UIViewController {
    var wsCtrl : ActorRef = AppActorSystem.shared.actorOf(WSRViewControler)
    
    override func viewDidLoad() {
        wsCtrl ! Connect(url: NSURL(string: "wss://echo.websocket.org")!, delegate: wsCtrl)
    }
}