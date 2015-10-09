//
//  WebSocketClient.swift
//  Actors
//
//  Created by Dario Lencina on 9/29/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Starscream

public class Connect : Message {
    public let url : NSURL
    public let delegate : ActorRef
    
    public init(url : NSURL, delegate : ActorRef) {
        self.url = url
        self.delegate = delegate
        super.init(sender: delegate)
    }
}

public class OnMessage : Message {
    public let message : String
    
    public init(sender: ActorRef, message : String) {
        self.message = message
        super.init(sender: sender)
    }
}

public class OnData : Message {
    public let data : NSData
    
    public init(sender: ActorRef, data : NSData) {
        self.data = data
        super.init(sender: sender)
    }
}

public class SendMessage : OnMessage {}

public class Disconnect : Message {}

public class OnDisconnect : Message {
    public let error : Optional<NSError>
    
    init(sender: Optional<ActorRef>, error :Optional<NSError>) {
        self.error = error
        super.init(sender: sender)
    }
}

public class OnConnect : Message {}

public class WebSocketClient : Actor , WebSocketDelegate {
    
    var socket : Optional<WebSocket> = Optional.None
    var delegate : Optional<ActorRef> = Optional.None
    
    public func websocketDidConnect(socket: WebSocket) {
        if let del = self.delegate {
            del ! OnConnect(sender: this)
            self.become("connected", state: connected)
        }
    }
    
    public func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        if let del = self.delegate {
            del ! OnDisconnect(sender: this, error: error)
            self.become("disconnected", state: disconnected)
        }
    }
    
    public func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        if let del = self.delegate {
            del ! OnMessage(sender: this, message: text)
        }
    }
    
    public func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        if let del = self.delegate {
            del ! OnData(sender: this, data: data)
        }
    }
    
    lazy var disconnected : Receive = {[unowned self](msg : Message) in
        switch (msg) {
        case is Connect:
            let c = msg as! Connect
            self.socket = WebSocket(url: NSURL(string: c.url.absoluteString)!)
            self.socket!.delegate = self
            self.delegate = c.sender
            self.socket!.connect()
            break
            
        case is Harakiri:
            self.this ! Disconnect(sender: Optional.None)
            break
            
        default:
            print("ignoring \(msg)")
            break
        }
    }
    
    lazy var connected : Receive = { [unowned self](msg : Message) in
        switch(msg) {
        case let c as SendMessage:
            if let s = self.socket {
                s.writeString(c.message)
            }
            break
            
        case is Disconnect:
            if let s = self.socket {
                s.disconnect()
                self.socket!.delegate = nil
                self.socket = nil
                self.unbecome()
            }
            break
            
        case is Harakiri:
            self.this ! Disconnect(sender: Optional.None)
            break
            
        default:
            print("ignoring \(msg)")
        }
    }
    
    override public func receive(msg : Message) {
        become("disconnected", state: disconnected)
        this ! (msg)
    }
}