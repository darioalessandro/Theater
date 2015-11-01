//
//  MultipeerMessages.swift
//  Actors
//
//  Created by Dario on 10/7/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Theater
import MultipeerConnectivity

public class Disconnect : Actor.Message {}

public class ConnectToDevice : Actor.Message {
    public let peer : MCPeerID
    
    public init(peer : MCPeerID, sender : Optional<ActorRef>) {
        self.peer = peer
        super.init(sender: sender)
    }
}

public class UICmd {
    
    public class AddMonitor : Actor.Message {}
    
    public class AddImageView : Actor.Message {
        let imageView : UIImageView
        
        public required init(imageView : UIImageView) {
            self.imageView = imageView
            super.init(sender: Optional.None)
        }
    }
    
    public class StartScanningWithLobbyViewController : Actor.Message {
        
        public let lobby : RolePickerController
        
        public init(sender: Optional<ActorRef>, lobby : RolePickerController) {
            self.lobby = lobby
            super.init(sender: sender)
        }
    }

    public class BecomeDevice : Actor.Message {}
    
    public class UnbecomeCamera : Actor.Message {}

    public class BecomeCamera : BecomeDevice {}
    
    public class UnbecomeMonitor : Actor.Message {}
    
    public class BecomeMonitor : BecomeDevice {}

    public class AddCameraController : Actor.Message {
        let ctrl : CameraViewController
        
        public init(sender: Optional<ActorRef>, ctrl : CameraViewController) {
            self.ctrl = ctrl
            super.init(sender: sender)
        }
    }
    
    public class TakePicture : Actor.Message {}
    
    public class OnPicture : Actor.Message {
        
        let pic : Optional<NSData>
        let error : Optional<NSError>
        
        public init(sender: Optional<ActorRef>, pic : NSData) {
            self.pic = Optional.Some(pic)
            self.error = Optional.None
            super.init(sender: sender)
        }
        
        public init(sender: Optional<ActorRef>, error : NSError) {
            self.pic = Optional.None
            self.error = Optional.Some(error)
            super.init(sender: sender)
        }
    }

}

public class DisconnectPeer : OnConnectToDevice{}

public class OnConnectToDevice : ConnectToDevice {}

public class RemoteCmd : Actor.Message {
    
    public class TakePic : RemoteCmd, NSCoding {
        
        public override init(sender: Optional<ActorRef>) {
            super.init(sender: sender)
        }
        
        public func encodeWithCoder(aCoder: NSCoder) {}
        
        public required init?(coder aDecoder: NSCoder) {
            super.init(sender: Optional.None)
        }
        
    }
    
    public class TakePicAck : Actor.Message, NSCoding {
        
        public override init(sender: Optional<ActorRef>) {
            super.init(sender: sender)
        }
        
        public func encodeWithCoder(aCoder: NSCoder) {}
        
        public required init?(coder aDecoder: NSCoder) {
            super.init(sender: Optional.None)
        }
    }
    
    public class TakePicResp : RemoteCmd, NSCoding {
        
        let pic : Optional<NSData>
        let error : Optional<NSError>
        
        
        public func encodeWithCoder(aCoder: NSCoder) {
            if let pic = self.pic {
                aCoder.encodeDataObject(pic)
            }
            
            if let error = self.error {
                aCoder.encodeObject(error, forKey: "error")
            }
        }
        
        public required init?(coder aDecoder: NSCoder) {
            if let pic = aDecoder.decodeDataObject() {
                self.pic = pic
            } else {
                self.pic = Optional.None
            }
            
            if let error = aDecoder.decodeObjectForKey("error") {
                self.error = Optional.Some(error as! NSError)
            }else {
                self.error = Optional.None
            }
            
            super.init(sender: Optional.None)
        }
        
        public init(sender: Optional<ActorRef>, pic : NSData) {
            self.pic = Optional.Some(pic)
            self.error = Optional.None
            super.init(sender: sender)
        }
        
        public init(sender: Optional<ActorRef>, pic : Optional<NSData>, error : Optional<NSError>) {
            self.pic = pic
            self.error = error
            super.init(sender: sender)
        }
        
        public init(sender: Optional<ActorRef>, error : NSError) {
            self.pic = Optional.None
            self.error = Optional.Some(error)
            super.init(sender: sender)
        }
    }
    
    public class SendFrame : Actor.Message, NSCoding {
        public let data : NSData
        public let fps : NSInteger
        init(data : NSData, sender : Optional<ActorRef>, fps : NSInteger) {
            self.data = data
            self.fps = fps
            
            super.init(sender: sender)
        }
        
        public func encodeWithCoder(aCoder: NSCoder) {
            aCoder.encodeDataObject(self.data)
            aCoder.encodeInteger(self.fps, forKey: "fps")
        }
        
        public required init?(coder aDecoder: NSCoder) {
            self.data = aDecoder.decodeDataObject()!
            self.fps = aDecoder.decodeIntegerForKey("fps")
            super.init(sender: Optional.None)
        }
    }
    
    public class OnFrame : Actor.Message {
        public let data : NSData
        public let peerId : MCPeerID
        public let fps : NSInteger
        
        init(data : NSData, sender : Optional<ActorRef>, peerId : MCPeerID, fps:NSInteger) {
            self.data = data
            self.peerId = peerId
            self.fps = fps
            super.init(sender: sender)
        }
    }
    
    public class PeerBecameCamera : Actor.Message , NSCoding {
        
        public init() {
            super.init(sender : Optional.None)
        }
        
        public func encodeWithCoder(aCoder: NSCoder) {}
        
        public required init?(coder aDecoder: NSCoder) {
            super.init(sender: Optional.None)
        }
    }
    
    public class PeerBecameMonitor : Actor.Message , NSCoding {
        
        public init() {
            super.init(sender : Optional.None)
        }
        
        public func encodeWithCoder(aCoder: NSCoder) {}
        
        public required init?(coder aDecoder: NSCoder) {
            super.init(sender: Optional.None)
        }
    }
}



