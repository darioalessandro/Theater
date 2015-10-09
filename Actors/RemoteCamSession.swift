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
    
    func cameraTakingPic(peer : MCPeerID,
        ctrl : CameraViewController,
        lobby : RolePickerController) -> Receive {
            let alert = UIAlertController(title: "Taking picture",
                message: Optional.None,
                preferredStyle: .Alert)
            
            ^{lobby.presentViewController(alert, animated: true, completion: nil)}
            
        return {[unowned self] (msg : Message) in
            print("camera")
            switch(msg) {
                case let t as RemoteCmd.TakePicResp:
                    ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                    do {try self.session.sendData(NSKeyedArchiver.archivedDataWithRootObject(t),
                        toPeers: self.session.connectedPeers,
                        withMode:.Reliable)
                    } catch let error as NSError {
                        print("error \(error)")
                        ^{
                            let a = UIAlertController(title: "Error sending pic",
                                message: Optional.None,
                                preferredStyle: .Alert)
                            ctrl.presentViewController(a, animated: true, completion: nil)
                        }
                    }
                    self.unbecome()
                    break
                
                case let c as DisconnectPeer:
                    ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                    if (c.peer.displayName == peer.displayName) {
                        self.unbecome()
                        self.this ! c
                    }
                    break
                    
                case is UnbecomeCamera:
                    ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                    self.unbecome()
                    break
                    
                case is Disconnect:
                    ^{alert.dismissViewControllerAnimated(true, completion: nil)}                    
                    self.unbecome()
                    self.this ! msg
                    break
                
                default:
                    self.receive(msg)
            }
        }
    }
    
    func cameraWithController(peer : MCPeerID,
                              ctrl : CameraViewController,
                             lobby : RolePickerController) -> Receive {
        return {[unowned self] (msg : Message) in
            print("camera")
            switch(msg) {
            case let s as SendFrame:
                do {try self.session.sendData(NSKeyedArchiver.archivedDataWithRootObject(s),
                        toPeers: self.session.connectedPeers,
                        withMode:.Unreliable)
                } catch let error as NSError {
                    print("error \(error)")
                }
                break
                
            case is RemoteCmd.TakePic:
                ^{ctrl.takePicture()}
                self.become(self.cameraTakingPic(peer, ctrl: ctrl, lobby : lobby))
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
    
    func camera(peer : MCPeerID, lobby : RolePickerController) -> Receive {
        return {[unowned self] (msg : Message) in
            print("camera")
            switch(msg) {
                case let c as DisconnectPeer:
                    if (c.peer.displayName == peer.displayName) {
                        self.unbecome()
                        self.this ! c
                    }
                    break
                
                case let c as AddCameraController:
                    self.become(self.cameraWithController(peer, ctrl: c.ctrl, lobby:lobby))
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
    
    func monitor(peer : MCPeerID, lobby : RolePickerController) -> Receive {
        return {[unowned self] (msg : Message) in
            print("monitor")
            switch(msg) {
                case is OnFrame:
                    print("ignoring frame")
                    break
                case let m as AddMonitor:
                    print("adding monitor")
                    self.become(self.monitorWithMonitor(m.sender!, peer: peer, lobby : lobby))
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
    
    func monitorTakingPicture(monitor : ActorRef,
                                 peer : MCPeerID,
                                lobby : RolePickerController) -> Receive {
        let alert = UIAlertController(title: "Requesting picture",
                                    message: Optional.None,
                             preferredStyle: .Alert)
        return {[unowned self] (msg : Message) in
            switch(msg) {
                case let takePic as RemoteCmd.TakePic:
                    ^{lobby.presentViewController(alert, animated: true, completion: nil)}
                    do {try self.session.sendData(NSKeyedArchiver.archivedDataWithRootObject(takePic),
                        toPeers: self.session.connectedPeers,
                        withMode:.Reliable)
                    } catch let error as NSError {
                        print("error \(error)")
                    }
                    break
                
                case let picResp as RemoteCmd.TakePicResp:
                    self.unbecome()
                    print("saving picture...")
                    ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                    if let imageData = picResp.pic, image = UIImage(data: imageData) {
                        UIImageWriteToSavedPhotosAlbum(image, self, "image:didFinishSavingWithError:contextInfo:", nil)
                    }else if let error = picResp.error {
                        ^{
                            let alert = UIAlertController(title: error.domain, message: error.localizedDescription, preferredStyle: .Alert)
                            let cancelAction = UIAlertAction(title: "Ok", style: .Cancel) { (action) in
                                alert.dismissViewControllerAnimated(true, completion: nil)
                            }
                            alert.addAction(cancelAction)
                            lobby.presentViewController(alert, animated: true, completion: nil)
                        }
                    }
                    
                    break
                case let c as DisconnectPeer:
                    ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                    if (c.peer.displayName == peer.displayName) {
                        self.unbecome()
                        self.this ! c
                    }
                    break
                    
                case is UnbecomeMonitor:
                    ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                    self.unbecome()
                    break
                    
                case is Disconnect:
                    ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                    self.unbecome()
                    self.this ! msg
                    break
                
                default:
                    print("sdfsdf")
            }
        }
    }
    
    func monitorWithMonitor(monitor : ActorRef,
                               peer : MCPeerID,
                              lobby : RolePickerController) -> Receive {
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
                    
                case is RemoteCmd.TakePic:
                    self.become(self.monitorTakingPicture(monitor, peer: peer, lobby: lobby))
                    self.this ! msg
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
    
    func connected(lobby : RolePickerController, peer : MCPeerID) -> Receive {
        return {[unowned self] (msg : Message) in
            print("Connected")
            switch(msg) {
                case is BecomeCamera:
                    self.become(self.camera(peer, lobby:lobby))
                    ^{lobby.showCamera()}
                    break
                case is BecomeMonitor:
                    self.become(self.monitor(peer, lobby:lobby))
                    ^{lobby.showRemote()}
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
    
    
    
    func scanning(lobby : RolePickerController) -> Receive {
        return {[unowned self] (msg : Message) in
            print("Scanning")
            switch(msg) {
                case is StartScanning:
                    self.startScanning(lobby)
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
            lobby.presentViewController(browser, animated: true, completion: { () -> Void in
                
            })
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
    
    public func browserViewControllerDidFinish(browserViewController: MCBrowserViewController) {
        browserViewController.dismissViewControllerAnimated(true) { () -> Void in }
    }
    
    public func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController) {
        browserViewController.dismissViewControllerAnimated(true) { () -> Void in }
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
            case let frame as SendFrame:
                this ! OnFrame(data: frame.data, sender: Optional.None, peerId : peerID, fps:frame.fps)
            break
            case let picReq as RemoteCmd.TakePic:
                this ! picReq
            break
            case let picResp as RemoteCmd.TakePicResp:
                this ! picResp
            break
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
