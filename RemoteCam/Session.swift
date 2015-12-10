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

public class RemoteCamSession : ViewCtrlActor<RolePickerController>, MCSessionDelegate, MCBrowserViewControllerDelegate {
    
    let states = States()
    
    var session : MCSession!
    
    let service : String = "RemoteCam"
    
    let peerID = MCPeerID(displayName: UIDevice.currentDevice().name)
    
    var mcAdvertiserAssistant : MCAdvertiserAssistant!
    
    public required init(context: ActorSystem, ref: ActorRef) {
        super.init(context: context, ref: ref)
    }
    
    override public func willStop() {
        if let adv = self.mcAdvertiserAssistant {
            adv.stop()
        }
        self.mcAdvertiserAssistant = nil
        self.session.delegate = nil
        self.session = nil
        self.browser = nil
    }
    
    func connected(lobby : RolePickerController,
                    peer : MCPeerID) -> Receive {
        ^{lobby.navigationItem.rightBarButtonItem?.title = lobby.states.disconnect}
        return {[unowned self] (msg : Actor.Message) in
            switch(msg) {
                
                case let m as UICmd.BecomeCamera:
                    self.become(self.states.camera, state: self.camera(peer, ctrl: m.ctrl, lobby: lobby))
                    self.sendMessage([peer], msg : RemoteCmd.PeerBecameCamera())

                case let m as UICmd.BecomeMonitor:
                    self.become(self.states.monitor, state:self.monitor(m.sender!, peer: peer, lobby: lobby))
                    self.sendMessage([peer], msg : RemoteCmd.PeerBecameMonitor())
                
                case is RemoteCmd.PeerBecameCamera:
                    ^{lobby.becomeMonitor()}
                
                case is RemoteCmd.PeerBecameMonitor:
                    ^{lobby.becomeCamera()}
                
                case is UICmd.ToggleConnect:
                    self.popAndStartScanning()

                case let c as DisconnectPeer:
                    if c.peer.displayName == peer.displayName {
                        self.popAndStartScanning()
                    }
                
                case is Disconnect:
                        self.popAndStartScanning()

                default:
                    self.receive(msg)
            }
        }
    }
    
    func popAndStartScanning() {
        self.popToState(self.states.scanning)
        self.this ! BLECentral.StartScanning(services: Optional.None, sender: this)
    }
    
    func scanning(lobby : RolePickerController) -> Receive {
        return {[unowned self] (msg : Actor.Message) in
            switch(msg) {
                
            case is BLECentral.StartScanning:
                self.startScanning(lobby)
                ^{lobby.navigationItem.rightBarButtonItem?.title = lobby.states.connect}
                
            case let w as OnConnectToDevice:
                if let c = self.browser {
                    c.dismissViewControllerAnimated(true, completion: {[unowned self] in
                        self.browser = nil
                    })
                }
                self.become(self.states.connected, state: self.connected(lobby, peer: w.peer))
                self.mcAdvertiserAssistant.stop()
                
            case is Disconnect:
                self.this ! BLECentral.StartScanning(services: Optional.None, sender: self.this)
                
            case is UICmd.BecomeCamera,
             is UICmd.BecomeMonitor,
             is UICmd.ToggleConnect:
                self.startScanning(lobby)
                
            default:
                self.receive(msg)
            }
        }
    }
    
    override public func receiveWithCtrl(ctrl: RolePickerController) -> Receive {
        return {[unowned self](msg : Message) in
            switch(msg) {
            case is UICmd.StartScanning:
                self.become(self.states.scanning, state:self.scanning(ctrl))
                self.this ! BLECentral.StartScanning(services: Optional.None, sender: self.this)
                
            default:
                self.receive(msg)
            }
        }
    }
    
    var browser : MCBrowserViewController?
    
    func startScanning(lobby : RolePickerController) {
        ^{lobby.navigationController?.popToViewController(lobby, animated: true)}
        ^{
            self.session = MCSession(peer: self.peerID)
            self.session.delegate = self
            self.browser = MCBrowserViewController(serviceType: self.service, session: self.session)
            
            if let browser = self.browser {
                browser.delegate = self;
                browser.minimumNumberOfPeers = 2
                browser.maximumNumberOfPeers = 2
                browser.modalPresentationStyle = UIModalPresentationStyle.FormSheet
                self.mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: self.service, discoveryInfo: nil, session: self.session)
                self.mcAdvertiserAssistant.start()
                lobby.presentViewController(browser, animated: true, completion: nil)
            }
        }
    }
    
    public func unableToProcessError(msg : Message) -> NSError {
        return NSError(domain: "Unable to process \(msg.dynamicType) command, since \(UIDevice.currentDevice().name) is not in the camera screen.", code: 0, userInfo: nil)
    }
    
    override public func receive(msg: Actor.Message) {
        switch (msg) {
            
            case let m as UICmd.BecomeCamera:
                ^{m.ctrl.navigationController?.popViewControllerAnimated(true)}
            
            case let m as UICmd.BecomeMonitor:
                m.sender! ! UICmd.BecomeMonitorFailed(sender : this)
            
            case is RemoteCmd.TakePic:
                let l = RemoteCmd.TakePicResp(sender: this, error: self.unableToProcessError(msg))
                self.sendMessage(self.session.connectedPeers, msg: l)
            
            case is RemoteCmd.ToggleCamera:
                let l = RemoteCmd.ToggleCameraResp(flashMode: nil, camPosition: nil, error: self.unableToProcessError(msg))
                self.sendMessage(self.session.connectedPeers, msg: l)
            
            case is RemoteCmd.ToggleFlash:
                let l = RemoteCmd.ToggleFlashResp(flashMode: nil, error: self.unableToProcessError(msg))
                self.sendMessage(self.session.connectedPeers, msg: l)
            
            default:
                super.receive(msg)
        }
    }
    
    @objc func image(image: UIImage, didFinishSavingWithError error: NSErrorPointer, contextInfo:UnsafePointer<Void>) {
        if error != nil {
            if let e = error.memory {
                this ! UICmd.FailedToSaveImage(sender: nil, error: e)
            }
        }
    }
    
    public func sendMessage(peer : [MCPeerID], msg : Actor.Message, mode : MCSessionSendDataMode = .Reliable) -> Try<Message> {
        do {
            try self.session.sendData(NSKeyedArchiver.archivedDataWithRootObject(msg),
            toPeers: peer,
            withMode:mode)
            return Success(value: msg)
        } catch let error as NSError {
            print("error \(error)")
            return Failure(error: error)
        }
    }
    
    public func browserViewControllerDidFinish(browserViewController: MCBrowserViewController) {
        browserViewController.dismissViewControllerAnimated(true) { () in }
    }
    
    public func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController) {
        //TODO: add dialog to force the person to connect with a phone
        browserViewController.dismissViewControllerAnimated(true) { () in }
    }
    
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
        
        switch (NSKeyedUnarchiver.unarchiveObjectWithData(data)) {
            case let frame as RemoteCmd.SendFrame:
                this ! RemoteCmd.OnFrame(data: frame.data, sender: nil, peerId: peerID, fps: frame.fps, camPosition:  frame.camPosition)
            
            case let m as Message:
                this ! m
            
            default:
                print("unable to unarchive")
        }
        
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
