//
//  RemoteCamSessionCamStates.swift
//  Actors
//
//  Created by Dario Lencina on 11/1/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Theater
import MultipeerConnectivity

extension RemoteCamSession {
    
    func cameraTakingPic(peer : MCPeerID,
        ctrl : CameraViewController,
        lobby : RolePickerController) -> Receive {
            let alert = UIAlertController(title: "Taking picture",
                message: Optional.None,
                preferredStyle: .Alert)
            
            ^{lobby.presentViewController(alert, animated: true, completion: nil)}
            
            return {[unowned self] (msg : Actor.Message) in
                switch(msg) {
                    
                case let t as UICmd.OnPicture:
                    
                    ^{alert.dismissViewControllerAnimated(true, completion: nil)}
                    
                    self.sendMessage([peer], msg: RemoteCmd.TakePicAck(sender: self.this))
                    
                    let result = self.sendMessage([peer], msg: RemoteCmd.TakePicResp(sender: self.this, pic:t.pic, error: t.error))
                    
                    if let failure = result as? Failure {
                        ^{
                            let a = UIAlertController(title: "Error sending pic",
                                message: failure.error.description,
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
            return {[unowned self] (msg : Actor.Message) in
                switch(msg) {
                case let m as UICmd.ToggleCameraResp:
                    self.sendMessage([peer], msg: RemoteCmd.ToggleCameraResp(flashMode: m.flashMode, camPosition: m.camPosition, error: nil))
                case let s as RemoteCmd.SendFrame:
                    self.sendMessage([peer], msg: s, mode: .Unreliable)
                    
                case is RemoteCmd.TakePic:
                    ^{ctrl.takePicture()}
                    self.become(self.states.cameraTakingPic,
                        state:self.cameraTakingPic(peer, ctrl: ctrl, lobby : lobby))
                    
                case is RemoteCmd.ToggleCamera:
                    let result = ctrl.toggleCamera()
                    var resp : Message?
                    if let (flashMode, camPosition) = result.toOptional() {
                        resp = RemoteCmd.ToggleCameraResp(flashMode: flashMode, camPosition: camPosition, error: nil)
                    } else if let failure = result as? Failure {
                        resp = RemoteCmd.ToggleCameraResp(flashMode: nil, camPosition: nil, error: failure.error)
                    }
                    self.sendMessage([peer], msg: resp!)
                    
                case is RemoteCmd.ToggleFlash:
                    let result = ctrl.toggleFlash()
                    var resp : Message?
                    if let flashMode = result.toOptional() {
                        resp = RemoteCmd.ToggleFlashResp(flashMode: flashMode, error: nil)
                    } else if let failure = result as? Failure {
                        resp = RemoteCmd.ToggleFlashResp(flashMode: nil, error: failure.error)
                    }
                    self.sendMessage([peer], msg: resp!)
                    
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
            return {[unowned self] (msg : Actor.Message) in
                
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
}