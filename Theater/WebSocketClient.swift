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

public class OnDisconnect : Message {}

public class OnConnect : Message {}

public class WebSocketClient : Actor , WebSocketDelegate {
    
    var socket : Optional<WebSocket> = Optional.None
    var delegate : Optional<ActorRef> = Optional.None
    
    public func websocketDidConnect(socket: WebSocket) {
        if let del = self.delegate {
            del ! OnConnect(sender: this)
        }
    }
    
    public func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        if let del = self.delegate {
            del ! OnDisconnect(sender: this)
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
    
    override public func receive(msg: Message) {
        
        switch (msg) {
            
            case is SendMessage:
                let c = msg as! SendMessage
                if let s = self.socket {
                    s.writeString(c.message)
                }
                break;
            
            case is Disconnect:
                if let s = self.socket {
                    s.disconnect()
                    self.socket!.delegate = nil
                    self.socket = nil
                }
                break;
            
            case is Connect:
                let c = msg as! Connect
                self.socket = WebSocket(url: NSURL(string: c.url.absoluteString)!)
                self.socket!.delegate = self
                self.delegate = c.sender
                self.socket!.connect()
            break;
            
            case is Harakiri:
                this ! Disconnect(sender: Optional.None)
                break;
            
            default:
                super.receive(msg)
                break;
        }
        
    }
}