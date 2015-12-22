//
//  WebSocketClient.swift
//  Actors
//
//  Created by Dario Lencina on 9/29/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Starscream

/**
WebSocketClient messages
*/

extension WebSocketClient {
    
    /**
    Connect command
    */

    public class Connect : Actor.Message {
        public let url : NSURL
        
        public init(url : NSURL, sender : ActorRef?) {
            self.url = url
            super.init(sender: sender)
        }
    }
    
    /**
     Disconnect command
     */

    public class Disconnect : Actor.Message {}
    
    /**
     Send message command
     */
    
    public class SendMessage : OnMessage {}
    
    /**
     Message broadcasted when there is an incoming WebSocket message
     */

    public class OnMessage : Actor.Message {
        public let message : String
        
        public init(sender: ActorRef?, message : String) {
            self.message = message
            super.init(sender: sender)
        }
    }
    
    /**
     Message broadcasted when there is incoming WebSocket data
     */

    public class OnData : Actor.Message {
        public let data : NSData
        
        public init(sender: ActorRef?, data : NSData) {
            self.data = data
            super.init(sender: sender)
        }
    }
    
    /**
     Message broadcasted when the websocket get's disconnected
     */

    public class OnDisconnect : Actor.Message {
        public let error : Optional<NSError>
        
        init(sender: Optional<ActorRef>, error :Optional<NSError>) {
            self.error = error
            super.init(sender: sender)
        }
    }
    
    /**
     Message broadcasted when the websocket get's connected
     */

    public class OnConnect : Actor.Message {}
        
}

/**
 Actor Wrapper for Starscream WebSocket
 */

public class WebSocketClient : Actor , WebSocketDelegate,  WithListeners {
    
    /**
     Collection with actors that care about changes in BLECentral
     */

    public var listeners : [ActorRef] = [ActorRef]()
    
    public required init(context: ActorSystem, ref: ActorRef) {
        super.init(context: context, ref:ref)
    }
    
    override public func preStart() {
        super.preStart()
        become("disconnected", state: disconnected)
    }
    
    /**
    websocketDidConnect
    */
    
    public func websocketDidConnect(socket: WebSocket) {
        self.broadcast(OnConnect(sender: this))
        self.become("connected", state: self.connected(socket))
    }
    
    /**
     websocketDidDisconnect
     */
    
    public func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        self.broadcast(OnDisconnect(sender: this, error: error))
        self.become("disconnected", state: disconnected)
    }
    
    /**
     websocketDidReceiveMessage
     */
    
    public func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        self.broadcast(OnMessage(sender: this, message: text))
    }
    
    /**
     websocketDidReceiveData
     */
    
    public func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        self.broadcast(OnData(sender: this, data: data))
    }
    
    /**
    stupid variable to keep websocket around.
    */
    var socket : WebSocket?
    
    /**
     disconnected is the initial state of the websocket
     */
    
    lazy var disconnected : Receive = {[unowned self](msg : Actor.Message) in
        switch (msg) {
        case let c as Connect:
            let socket = WebSocket(url: NSURL(string: c.url.absoluteString)!)
            self.socket = socket
            socket.delegate = self
            self.addListener(c.sender)
            socket.connect()
            
        default:
            self.receive(msg)
        }
    }
    
    /**
     state when the websocket is connected
     */
    
    func connected(socket: WebSocket) -> Receive {
        return {[weak self](msg : Actor.Message) in
            switch(msg) {
            case let c as SendMessage:
                socket.writeString(c.message)
                
            case is Disconnect:
                socket.disconnect()
                socket.delegate = nil
                if let selfo = self {
                    selfo.unbecome()
                }
                
            default:
                if let selfo = self {
                    selfo.receive(msg)
                }
            }
        }
    }
    
    /**
    Cleanup
    */
    
    deinit {
        //TODO: evil hack to kill socket
        if let state = self.statesStack.head() {
            state.1(Disconnect(sender: nil))
        }
    }
    
}