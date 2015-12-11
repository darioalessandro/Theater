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
    
    func monitorTogglingFlash(monitor : ActorRef,
        peer : MCPeerID,
        lobby : RolePickerController) -> Receive {
            let alert = UIAlertController(title: "Requesting flash toggle",
                message: nil,
                preferredStyle: .Alert)
            return {[unowned self] (msg : Actor.Message) in
                switch(msg) {
                    
                case is UICmd.ToggleFlash:
                    ^{lobby.presentViewController(alert, animated: true, completion: {
                        if let f = self.sendMessage([peer], msg: RemoteCmd.ToggleFlash()) as? Failure {
                            self.this ! RemoteCmd.ToggleFlashResp(flashMode: nil, error: f.error)
                        }
                    })}
                    
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
                message: nil,
                preferredStyle: .Alert)
            
            return {[unowned self] (msg : Actor.Message) in
                switch(msg) {
                    
                case is UICmd.ToggleCamera:
                    ^{lobby.presentViewController(alert, animated: true, completion: {
                        if let f =  self.sendMessage([peer], msg: RemoteCmd.ToggleCamera()) as? Failure {
                            self.this ! RemoteCmd.ToggleCameraResp(flashMode: nil, camPosition: nil, error: f.error)
                        }
                    })}
                    
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
                message: nil,
                preferredStyle: .Alert)
            return {[unowned self] (msg : Actor.Message) in
                switch(msg) {
                    
                case is RemoteCmd.TakePicAck:
                    ^{alert.title = "Receiving picture"}
                    self.sendMessage([peer], msg: msg)
                    
                case is UICmd.TakePicture:
                    ^{lobby.presentViewController(alert, animated: true, completion: {
                        self.sendMessage([peer], msg: RemoteCmd.TakePic(sender: self.this))
                    })}
                    
                case let picResp as RemoteCmd.TakePicResp:
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
                    ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                    print("sdfsdf")
                }
            }
    }
    
    func monitor(monitor : ActorRef,
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