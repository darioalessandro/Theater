//
//  SessionMonitorStates.swift
//  Actors
//
//  Created by Dario Lencina on 11/1/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Theater
import MultipeerConnectivity

extension RemoteCamSession {
    
    func monitor(peer : MCPeerID,
        lobby : RolePickerController) -> Receive {
            return {[unowned self] (msg : Actor.Message) in
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
    
    func monitorTogglingFlash(monitor : ActorRef,
        peer : MCPeerID,
        lobby : RolePickerController) -> Receive {
            let alert = UIAlertController(title: "Requesting flash toggle",
                message: Optional.None,
                preferredStyle: .Alert)
            return {[unowned self] (msg : Actor.Message) in
                switch(msg) {
                    
                case is UICmd.ToggleFlash:
                    ^{lobby.presentViewController(alert, animated: true, completion: nil)}
                    
                    if let f = self.sendMessage([peer], msg: RemoteCmd.ToggleFlash()) as? Failure {
                        self.this ! RemoteCmd.ToggleFlashResp(flashMode: nil, error: f.error)
                    }
                    
                case let t as RemoteCmd.ToggleFlashResp:
                    monitor ! UICmd.ToggleFlashResp(flashMode: t.flashMode, error: t.error)
                    if let _ = t.flashMode {
                        monitor ! t
                        ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                    }else if let error = t.error {
                        ^{alert.dismissViewControllerAnimated(true, completion:{
                            let a = UIAlertController(title: error.domain, message: nil, preferredStyle: .Alert)
                            
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
    
    func monitorTogglingCamera(monitor : ActorRef,
        peer : MCPeerID,
        lobby : RolePickerController) -> Receive {
            let alert = UIAlertController(title: "Requesting camera toggle",
                message: Optional.None,
                preferredStyle: .Alert)
            return {[unowned self] (msg : Actor.Message) in
                switch(msg) {
                    
                case is UICmd.ToggleCamera:
                    ^{lobby.presentViewController(alert, animated: true, completion: nil)}
                    
                    if let f =  self.sendMessage([peer], msg: RemoteCmd.ToggleCamera()) as? Failure {
                        self.this ! RemoteCmd.ToggleCameraResp(flashMode: nil, camPosition: nil, error: f.error)
                    }
                    
                    
                case let t as RemoteCmd.ToggleCameraResp:
                    monitor ! UICmd.ToggleCameraResp(flashMode: t.flashMode, camPosition: t.camPosition, error: t.error)
                    if let _ = t.flashMode {
                        ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                    }else if let error = t.error {
                        ^{alert.dismissViewControllerAnimated(true, completion:{
                            let a = UIAlertController(title: error.domain, message: nil, preferredStyle: .Alert)
                            
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
    
    func monitorTakingPicture(monitor : ActorRef,
        peer : MCPeerID,
        lobby : RolePickerController) -> Receive {
            let alert = UIAlertController(title: "Requesting picture",
                message: Optional.None,
                preferredStyle: .Alert)
            return {[unowned self] (msg : Actor.Message) in
                switch(msg) {
                    
                case is RemoteCmd.TakePicAck:
                    ^{alert.title = "Receiving picture"}
                    self.sendMessage([peer], msg: msg)
                    
                case is UICmd.TakePicture:
                    ^{lobby.presentViewController(alert, animated: true, completion: nil)}
                    self.sendMessage([peer], msg: RemoteCmd.TakePic(sender: self.this))
                    
                case let picResp as RemoteCmd.TakePicResp:
                    print("saving picture...")
                    if let imageData = picResp.pic, image = UIImage(data: imageData) {
                        UIImageWriteToSavedPhotosAlbum(image, self, "image:didFinishSavingWithError:contextInfo:", nil)
                        ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                    }else if let error = picResp.error {
                        ^{alert.dismissViewControllerAnimated(true, completion:{ () in
                            let a = UIAlertController(title: error.domain, message: nil, preferredStyle: .Alert)
                            
                            a.addAction(UIAlertAction(title: "Ok", style: .Cancel) { (action) in
                                a.dismissViewControllerAnimated(true, completion: nil)
                                })
                            
                            lobby.presentViewController(a, animated: true, completion: nil)
                        })}
                    }
                    self.unbecome()
                    
                case is UICmd.UnbecomeMonitor:
                    ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                    self.popToState(self.states.connected)
                    
                case let c as DisconnectPeer:
                    if c.peer.displayName == peer.displayName {
                        ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                        self.popAndStartScanning()
                    }
                    
                case is Disconnect:
                    ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                    self.popAndStartScanning()
                    
                default:
                    print("sdfsdf")
                }
            }
    }
    
    func monitorWithMonitor(monitor : ActorRef,
        peer : MCPeerID,
        lobby : RolePickerController) -> Receive {
            return {[unowned self] (msg : Actor.Message) in
                switch(msg) {
                case is RemoteCmd.OnFrame:
                    monitor ! msg
                    
                case is UICmd.UnbecomeMonitor:
                    self.popToState(self.states.connected)
                    
                case let c as DisconnectPeer:
                    if c.peer.displayName == peer.displayName {
                        self.popAndStartScanning()
                    }
                    
                case is UICmd.ToggleCamera:
                    self.become(self.states.monitorTakingPicture, state:
                        self.monitorTogglingCamera(monitor, peer: peer, lobby: lobby))
                    self.this ! msg
                    
                case is UICmd.ToggleFlash:
                    self.become(self.states.monitorTogglingFlash, state:
                        self.monitorTogglingFlash(monitor, peer: peer, lobby: lobby))
                    self.this ! msg
                    
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
}