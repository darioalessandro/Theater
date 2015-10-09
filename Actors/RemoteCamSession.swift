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
    
    let peerID = MCPeerID(displayName: UIDevice.currentDevice().name)
    
    var mcAdvertiserAssistant : MCAdvertiserAssistant!
    
    public required init(context: ActorSystem, ref: ActorRef) {
        super.init(context: context, ref: ref)
        become(self.idle)
    }
    
    func camera(peer : MCPeerID) -> Receive {
        return {[unowned self] (msg : Message) in
            print("camera")
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
                
            case let c as DisconnectPeer:
                if (c.peer.displayName == peer.displayName) {
                    self.unbecome()
                    self.this ! c
                }
                break
                
                case is UnbecomeCamera:
                    self.unbecome()
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
    
    func monitor(peer : MCPeerID) -> Receive {
        return {[unowned self] (msg : Message) in
            print("monitor")
            switch(msg) {
                case is OnFrame:
                    print("ignoring frame")
                    break
                case let m as AddMonitor:
                    print("adding monitor")
                    self.become(self.monitorWithMonitor(m.sender!, peer: peer))
                    break
                
                case is UnbecomeMonitor:
                    self.unbecome()
                    break
                
                case let c as DisconnectPeer:
                    if (c.peer.displayName == peer.displayName) {
                        self.unbecome()
                        self.this ! c
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
    
    func monitorWithMonitor(monitor : ActorRef,peer : MCPeerID) -> Receive {
        return {[unowned self] (msg : Message) in
            print("monitorWithMonitor")
            switch(msg) {
            case is OnFrame:
                monitor ! msg
                break
            case is UnbecomeMonitor:
                self.unbecome()
                self.this ! msg
                break
            case let c as DisconnectPeer:
                if (c.peer.displayName == peer.displayName) {
                    self.unbecome()
                    self.this ! c
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
    
    func connected(lobby : LobbyViewController, peer : MCPeerID) -> Receive {
        return {[unowned self] (msg : Message) in
            print("Connected")
            switch(msg) {
                case is BecomeCamera:
                    self.become(self.camera(peer))
                    ^{
                        lobby.showCamera()
                    }
                    break
                case is BecomeMonitor:
                    self.become(self.monitor(peer))
                    ^{
                        lobby.showRemote()
                    }
                    break
                case let c as DisconnectPeer:
                    if (c.peer.displayName == peer.displayName) {
                        self.unbecome()
                        self.this ! StartScanning()
                    }
                    break
                
                case is Disconnect:
                    self.unbecome()
                    break
                default:
                    self.receive(msg)
            }
        }
    }
    
    
    
    func scanning(lobby : LobbyViewController) -> Receive {
        return {[unowned self] (msg : Message) in
            print("Scanning")
            switch(msg) {
                case is StartScanning:
                    ^{
                        lobby.navigationController?.popToViewController(lobby, animated: true)
                    }
                    self.session = MCSession(peer: self.peerID)
                    self.session.delegate = self
                    ^{
                        let browser = MCBrowserViewController(serviceType: self.service, session: self.session);
                        browser.delegate = self;
                        browser.minimumNumberOfPeers = 2
                        browser.maximumNumberOfPeers = 2
                        browser.modalPresentationStyle = UIModalPresentationStyle.FormSheet
                        self.mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: self.service, discoveryInfo: nil, session: self.session)
                        self.mcAdvertiserAssistant.start()
                        lobby.presentViewController(browser, animated: true, completion: { () -> Void in
                            
                        })
                    }

                    break
                case let w as OnConnectToDevice:
                    self.become(self.connected(lobby, peer: w.peer))
                    self.mcAdvertiserAssistant.stop()
                    break
                case is Disconnect:
                    self.session.disconnect()
                    self.unbecome()
                    break
                default:
                    self.receive(msg)
            }
        }
    }
    
    lazy var idle : Receive = {[unowned self] (msg : Message) in
        print("idle")
        switch(msg) {
            case let w as StartScanningWithLobbyViewController:
                self.become(self.scanning(w.lobby))
                self.this ! StartScanning()
                break
            default:
                self.receive(msg)
        }
    }
    
    //MCBrowser
    
    public func browserViewControllerDidFinish(browserViewController: MCBrowserViewController) {
        browserViewController.dismissViewControllerAnimated(true) { () -> Void in }
    }
    
    public func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController) {
        browserViewController.dismissViewControllerAnimated(true) { () -> Void in }
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
            self.this ! DisconnectPeer(peer : peerID, sender : this)
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
