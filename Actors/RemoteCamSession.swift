//
//  RemoteCamSession.swift
//  Actors
//
//  Created by Dario on 10/7/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Theater
import MultipeerConnectivity

public class RemoteCamSession : Actor, MCSessionDelegate {
    
    var session : MCSession
    
    public required init(context: ActorSystem, ref: ActorRef) {
        let peerID = MCPeerID(displayName: UIDevice.currentDevice().name)
        self.session = MCSession(peer: peerID)
        super.init(context: context, ref: ref)
        self.become(scanning)
        self.session.delegate = self
    }
    
    func camera(camViewController : UIViewController) -> Receive {
        return {[unowned self] (msg : Message) in
            switch(msg) {
                case let s as SendFrame:
                    //TODO: include Paracon to mantain stream connection or send it through the session
                break
                case is Disconnect:
                    self.unbecome()
                    self.this ! msg
                break
                default:
                    self.receive(msg)
                
            }
    }
    }
    
    lazy var monitor : Receive = {[unowned self] (msg : Message) in
        switch(msg) {
            case let s as OnFrame:
                //TODO: include Paracon to mantain stream connection or send it through the session
                break
            case is Disconnect:
                self.unbecome()
                self.this ! msg
                break
            default:
                self.receive(msg)
        }
    }
    
    lazy var connected : Receive = {[unowned self] (msg : Message) in
        switch(msg) {
            case let camera as BecomeCamera:
                //self.become(self.camera)
                break
            case let monitor as BecomeMonitor:
                self.become(self.monitor)
                break
            case is Disconnect:
                self.unbecome()
                break
            default:
                self.receive(msg)
        }
    }
    
    lazy var scanning : Receive = {[unowned self] (msg : Message) in
        switch(msg) {
            case let w as StartScanning:
                print("Already scanning")
                break
            case let w as Disconnect:
                self.session.disconnect()
                self.unbecome()
                break
            default:
                self.receive(msg)
        }
    }
    
    lazy var idle : Receive = {[unowned self] (msg : Message) in
        switch(msg) {
            case let w as StartScanning:
                self.become(self.scanning)
                break
            default:
                self.receive(msg)
        }
    }
    
    //MCSession delegate garbage
    
    public func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        switch state {
        case MCSessionState.Connected:
            print("Connected: \(peerID.displayName)")
            
        case MCSessionState.Connecting:
            print("Connecting: \(peerID.displayName)")
            
        case MCSessionState.NotConnected:
            print("Not Connected: \(peerID.displayName)")
        }
    }
    
    public func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        
    }
    
    public func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    public func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        
    }
    
    public func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        
    }
    
    public func session(session: MCSession, didReceiveCertificate certificate: [AnyObject]?, fromPeer peerID: MCPeerID, certificateHandler: (Bool) -> Void) {
            certificateHandler(true)
    }
    
}
