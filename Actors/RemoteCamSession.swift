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

public class RemoteCamSession : Actor, MCSessionDelegate, MCBrowserViewControllerDelegate {
    
    var session : MCSession!
    
    let service : String = "RemoteCam"
    
    var lobby : LobbyViewController!
    
    let peerID = MCPeerID(displayName: UIDevice.currentDevice().name)
    
    public required init(context: ActorSystem, ref: ActorRef) {
        super.init(context: context, ref: ref)
        become(self.idle)
    }
    
    func camera(camera : ActorRef) -> Receive {
        return {[unowned self] (msg : Message) in
            switch(msg) {
                case let s as SendFrame:
                    do {
                        try self.session.sendData(s.data,
                            toPeers: self.session.connectedPeers,
                            withMode:.Unreliable)
                    } catch let error as NSError {
                        print("error \(error)")
                    }
                    
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
    
    func monitor(monitor : ActorRef) -> Receive {
        return {[unowned self] (msg : Message) in
            switch(msg) {
                case is OnFrame:
                    monitor ! msg
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
    
    lazy var connected : Receive = {[unowned self] (msg : Message) in
        switch(msg) {
            case let c as BecomeCamera:
                self.become(self.camera(c.sender!))
                break
            case let m as BecomeMonitor:
                self.become(self.monitor(m.sender!))
                break
            case is Disconnect:
                self.unbecome()
                break
            default:
                self.receive(msg)
        }
    }
    
    func scanning(lobby : LobbyViewController) -> Receive {
        
        let browser = MCBrowserViewController(serviceType: service, session: self.session);
        browser.delegate = self;
        browser.minimumNumberOfPeers = 2
        browser.maximumNumberOfPeers = 2
        browser.modalPresentationStyle = UIModalPresentationStyle.FormSheet
        
        return {[unowned self] (msg : Message) in
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
    }
    
    lazy var idle : Receive = {[unowned self] (msg : Message) in
        switch(msg) {
            case let w as StartScanningWithLobbyViewController:
                self.lobby = w.lobby
                self.session = MCSession(peer: self.peerID)
                self.session.delegate = self
                self.become(self.scanning(w.lobby))
                break
            default:
                self.receive(msg)
        }
    }
    
    //MCBrowser
    
    public func browserViewControllerDidFinish(browserViewController: MCBrowserViewController) {
        browserViewController.dismissViewControllerAnimated(true) { () -> Void in
            
        }
    }
    
    public func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController) {
        browserViewController.dismissViewControllerAnimated(true) { () -> Void in
            
        }
    }
    
    //MCSession delegate garbage
    
    public func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        switch state {
        case MCSessionState.Connected:
            self.this ! OnConnectToDevice(peer : peerID, sender : this)
            print("Connected: \(peerID.displayName)")
            
        case MCSessionState.Connecting:
            print("Connecting: \(peerID.displayName)")
            
        case MCSessionState.NotConnected:
            print("Not Connected: \(peerID.displayName)")
        }
    }
    
    public func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        this ! OnFrame(data: data, sender: Optional.None, peerId : peerID)
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
