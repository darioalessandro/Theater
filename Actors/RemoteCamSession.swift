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
    
    let states = States()
    
    var session : MCSession!
    
    let service : String = "RemoteCam"
    
    let peerID = MCPeerID(displayName: UIDevice.currentDevice().name)
    
    var mcAdvertiserAssistant : MCAdvertiserAssistant!
    
    public required init(context: ActorSystem, ref: ActorRef) {
        super.init(context: context, ref: ref)
        become(self.states.idle, state: self.idle)
    }
    
    func cameraTakingPic(peer : MCPeerID,
        ctrl : CameraViewController,
        lobby : RolePickerController) -> Receive {
            let alert = UIAlertController(title: "Taking picture",
                message: Optional.None,
                preferredStyle: .Alert)
            
            ^{lobby.presentViewController(alert, animated: true, completion: nil)}
            
        return {[unowned self] (msg : Message) in
            switch(msg) {
                
                case let t as UICmd.OnPicture:
                    
                    ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                    
                    let ack = RemoteCmd.TakePicAck(sender: self.this)
                    
                    do {try self.session.sendData(NSKeyedArchiver.archivedDataWithRootObject(ack),
                        toPeers: self.session.connectedPeers,
                        withMode:.Reliable)
                    } catch let error as NSError {
                        print("error \(error)")
                    }
                    
                    let resp = RemoteCmd.TakePicResp(sender: self.this, pic:t.pic, error: t.error)
                    
                    do {try self.session.sendData(NSKeyedArchiver.archivedDataWithRootObject(resp),
                        toPeers: self.session.connectedPeers,
                        withMode:.Reliable)
                    } catch let error as NSError {
                        print("error \(error)")
                        ^{
                            let a = UIAlertController(title: "Error sending pic",
                                message: Optional.None,
                                preferredStyle: .Alert)
                            
                            a.addAction(UIAlertAction(title: "Ok", style: .Cancel) { (action) in
                                a.dismissViewControllerAnimated(true, completion: nil)
                                })
                            
                            ctrl.presentViewController(a, animated: true, completion: nil)
                        }
                    }
                    self.unbecome()
                
                case let c as DisconnectPeer:
                    ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                    if (c.peer.displayName == peer.displayName) {
                        self.popAndStartScanning()
                    }
                
                case is Disconnect:
                    ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                    self.popAndStartScanning()
                    
                case is UICmd.UnbecomeCamera:
                    ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                    self.popAndStartScanning()
                
                default:
                    self.receive(msg)
            }
        }
    }
    
    func cameraWithController(peer : MCPeerID,
                              ctrl : CameraViewController,
                             lobby : RolePickerController) -> Receive {
        return {[unowned self] (msg : Message) in
            switch(msg) {
            case let s as RemoteCmd.SendFrame:
                do {try self.session.sendData(NSKeyedArchiver.archivedDataWithRootObject(s),
                        toPeers: self.session.connectedPeers,
                        withMode:.Unreliable)
                } catch let error as NSError {
                    print("error \(error)")
                }
                
            case is RemoteCmd.TakePic:
                ^{ctrl.takePicture()}
                self.become(self.states.cameraTakingPic,
                            state:self.cameraTakingPic(peer, ctrl: ctrl, lobby : lobby))
                
            case is UICmd.UnbecomeCamera:
                self.popToState(self.states.connected)
                
            case let c as DisconnectPeer:
                if (c.peer.displayName == peer.displayName) {
                    self.popAndStartScanning()
                }
                
            case is Disconnect:
                self.popAndStartScanning()
                
            default:
                self.receive(msg)
            }
        }
    }
    
    func camera(peer : MCPeerID,
               lobby : RolePickerController) -> Receive {
        return {[unowned self] (msg : Message) in

            switch(msg) {
                case let c as UICmd.AddCameraController:
                    self.become(self.states.cameraWithController,
                         state:self.cameraWithController(peer, ctrl: c.ctrl, lobby:lobby))
                
                case is UICmd.UnbecomeCamera:
                    self.popToState(self.states.connected)
                
                case is Disconnect:
                    self.popAndStartScanning()

                case let c as DisconnectPeer:
                    if (c.peer.displayName == peer.displayName) {
                        self.popAndStartScanning()
                    }
                
                default:
                    self.receive(msg)
                
            }
        }
    }
    
    func monitor(peer : MCPeerID,
                lobby : RolePickerController) -> Receive {
        return {[unowned self] (msg : Message) in
            switch(msg) {
                case is RemoteCmd.OnFrame:
                    print("ignoring frame")

                case let m as UICmd.AddMonitor:
                    print("adding monitor")
                    self.become(self.states.monitorWithMonitor,
                        state: self.monitorWithMonitor(m.sender!, peer: peer, lobby : lobby))
                
                case is UICmd.UnbecomeMonitor:
                    self.popToState(self.states.connected)
                
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
    
    func monitorTakingPicture(monitor : ActorRef,
                                 peer : MCPeerID,
                                lobby : RolePickerController) -> Receive {
        let alert = UIAlertController(title: "Requesting picture",
                                    message: Optional.None,
                             preferredStyle: .Alert)
        return {[unowned self] (msg : Message) in
            switch(msg) {
                
                case is RemoteCmd.TakePicAck:
                    ^{alert.title = "Receiving picture"}
                    do {try self.session.sendData(NSKeyedArchiver.archivedDataWithRootObject(msg),
                        toPeers: self.session.connectedPeers,
                        withMode:.Reliable)
                    } catch let error as NSError {
                        print("error \(error)")
                    }
                
                case is UICmd.TakePicture:
                    let cmd = RemoteCmd.TakePic(sender: self.this)
                    ^{lobby.presentViewController(alert, animated: true, completion: nil)}
                    do {try self.session.sendData(NSKeyedArchiver.archivedDataWithRootObject(cmd),
                        toPeers: self.session.connectedPeers,
                        withMode:.Reliable)
                    } catch let error as NSError {
                        print("error \(error)")
                    }
                
                case let picResp as RemoteCmd.TakePicResp:
                    print("saving picture...")
                    if let imageData = picResp.pic, image = UIImage(data: imageData) {
                        UIImageWriteToSavedPhotosAlbum(image, self, "image:didFinishSavingWithError:contextInfo:", nil)
                        ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                    }else if let error = picResp.error {
                        ^{alert.dismissViewControllerAnimated(true, completion:{ () in
                            let a = UIAlertController(title: error.domain, message: error.localizedDescription, preferredStyle: .Alert)
                            
                            a.addAction(UIAlertAction(title: "Ok", style: .Cancel) { (action) in
                                a.dismissViewControllerAnimated(true, completion: nil)
                                })
                            
                            lobby.presentViewController(a, animated: true, completion: nil)
                        })}
                    }
                    self.unbecome()
                
                case let c as DisconnectPeer:
                    if c.peer.displayName == peer.displayName {
                        ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                        self.popAndStartScanning()
                    }
                
                case is Disconnect:
                    ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                    self.popAndStartScanning()
                
                case is UICmd.UnbecomeMonitor:
                    ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                    self.popToState(self.states.connected)
                
                default:
                    print("sdfsdf")
            }
        }
    }
    
    func monitorWithMonitor(monitor : ActorRef,
                               peer : MCPeerID,
                              lobby : RolePickerController) -> Receive {
        return {[unowned self] (msg : Message) in
            switch(msg) {
                case is RemoteCmd.OnFrame:
                    monitor ! msg
                    
                case is UICmd.UnbecomeMonitor:
                    self.popToState(self.states.connected)
                    
                case let c as DisconnectPeer:
                    if c.peer.displayName == peer.displayName {
                        self.popAndStartScanning()
                    }
                    
                case is UICmd.TakePicture:
                    self.become(self.states.monitorTakingPicture, state:
                        self.monitorTakingPicture(monitor, peer: peer, lobby: lobby))
                    self.this ! msg
                    
                case is Disconnect:
                        self.popAndStartScanning()
                    
                default:
                    self.receive(msg)
                }
        }
    }
    
    func connected(lobby : RolePickerController,
                    peer : MCPeerID) -> Receive {
        return {[unowned self] (msg : Message) in
            switch(msg) {
                
                case is UICmd.BecomeCamera:
                    self.become(self.states.camera, state: self.camera(peer, lobby:lobby))
                    ^{lobby.showCamera()}
                    self.fireAndForget(peer, message : RemoteCmd.PeerBecameCamera())

                case is UICmd.BecomeMonitor:
                    self.become(self.states.monitor, state:self.monitor(peer, lobby:lobby))
                    ^{lobby.showRemote()}
                    self.fireAndForget(peer, message : RemoteCmd.PeerBecameMonitor())
                
                case is RemoteCmd.PeerBecameCamera:
                    self.this ! UICmd.BecomeMonitor(sender:self.this)
                
                case is RemoteCmd.PeerBecameMonitor:
                    self.this ! UICmd.BecomeCamera(sender:self.this)

                case let c as DisconnectPeer:
                    if (c.peer.displayName == peer.displayName) {
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
        self.this ! BLECentralMsg.StartScanning(services: Optional.None, sender: this)
    }
    
    func scanning(lobby : RolePickerController) -> Receive {
        return {[unowned self] (msg : Message) in
            switch(msg) {
            case is BLECentralMsg.StartScanning:
                self.startScanning(lobby)
                
            case let w as OnConnectToDevice:
                self.become(self.states.connected, state: self.connected(lobby, peer: w.peer))
                self.mcAdvertiserAssistant.stop()
                
            case is Disconnect:
                self.this ! BLECentralMsg.StartScanning(services: Optional.None, sender: self.this)
                
            default:
                self.receive(msg)
            }
        }
    }
    
    lazy var idle : Receive = {[unowned self] (msg : Message) in
        switch(msg) {
            case let w as UICmd.StartScanningWithLobbyViewController:
                self.become(self.states.scanning, state:self.scanning(w.lobby))
                self.this ! BLECentralMsg.StartScanning(services: Optional.None, sender: self.this)

            default:
                self.receive(msg)
        }
    }
    
    func startScanning(lobby : RolePickerController) {
        ^{lobby.navigationController?.popToViewController(lobby, animated: true)}
        ^{
            self.session = MCSession(peer: self.peerID)
            self.session.delegate = self
            let browser = MCBrowserViewController(serviceType: self.service, session: self.session);
            browser.delegate = self;
            browser.minimumNumberOfPeers = 2
            browser.maximumNumberOfPeers = 2
            browser.modalPresentationStyle = UIModalPresentationStyle.FormSheet
            self.mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: self.service, discoveryInfo: nil, session: self.session)
            self.mcAdvertiserAssistant.start()
            lobby.presentViewController(browser, animated: true, completion: nil)
        }
    }
    
    override public func receive(msg: Message) {
        switch (msg) {
            case is RemoteCmd.TakePic:
                let l = RemoteCmd.TakePicResp(sender: this, error: NSError(domain: "unable to take picture since \(UIDevice.currentDevice().name) is not in the camera screen", code: 0, userInfo: nil))
                do {try self.session.sendData(NSKeyedArchiver.archivedDataWithRootObject(l),
                    toPeers: self.session.connectedPeers,
                    withMode:.Reliable)
                } catch let error as NSError {
                    print("error \(error)")
            }
            
            default:
                super.receive(msg)
        }
    }
    
    @objc func image(image: UIImage, didFinishSavingWithError error: NSErrorPointer, contextInfo:UnsafePointer<Void>) {
        if error != nil {
            ^{
                print("error \(error)")
//                UIAlertController(title: "Error saving image", message: nil, preferredStyle: .Alert)
            }
        }
    }
    
    public func fireAndForget(peer : MCPeerID, message : Message) {
        do {try self.session.sendData(NSKeyedArchiver.archivedDataWithRootObject(message),
            toPeers: [peer],
            withMode:.Reliable)
        }
        catch let error as NSError {
            print("error \(error)")
        }
    }
    
    public func browserViewControllerDidFinish(browserViewController: MCBrowserViewController) {
        browserViewController.dismissViewControllerAnimated(true) { () in }
    }
    
    public func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController) {
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
        let remote = ActorRef(context: AppActorSystem.shared, path: ActorPath(path: "theOtherDevice"))
        switch (NSKeyedUnarchiver.unarchiveObjectWithData(data)) {
            case let frame as RemoteCmd.SendFrame:
                this ! RemoteCmd.OnFrame(data: frame.data, sender: remote, peerId : peerID, fps:frame.fps)

            case is RemoteCmd.TakePic:
                this ! RemoteCmd.TakePic(sender: remote)

            case let picResp as RemoteCmd.TakePicResp:
                this ! RemoteCmd.TakePicResp(sender: remote, pic : picResp.pic, error : picResp.error)

            case is RemoteCmd.TakePicAck:
                this ! RemoteCmd.TakePicAck(sender:remote)
            
            case let a as RemoteCmd.PeerBecameCamera:
                this ! a
            
            case let a as RemoteCmd.PeerBecameMonitor:
                this ! a
            
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
