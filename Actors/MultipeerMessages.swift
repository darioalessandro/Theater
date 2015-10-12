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

public class Disconnect : Message {}

public class ConnectToDevice : Message {
    public let peer : MCPeerID
    
    public init(peer : MCPeerID, sender : Optional<ActorRef>) {
        self.peer = peer
        super.init(sender: sender)
    }
}

public class UICmd {
    
    public class AddMonitor : Message {}
    
    public class AddImageView : Message {
        let imageView : UIImageView
        
        public required init(imageView : UIImageView) {
            self.imageView = imageView
            super.init(sender: Optional.None)
        }
    }
    
    public class StartScanningWithLobbyViewController : Message {
        
        public let lobby : RolePickerController
        
        public init(sender: Optional<ActorRef>, lobby : RolePickerController) {
            self.lobby = lobby
            super.init(sender: sender)
        }
    }

    public class BecomeDevice : Message {}
    
    public class UnbecomeCamera : Message {}

    public class BecomeCamera : BecomeDevice {}
    
    public class UnbecomeMonitor : Message {}
    
    public class BecomeMonitor : BecomeDevice {}

    public class AddCameraController : Message {
        let ctrl : CameraViewController
        
        public init(sender: Optional<ActorRef>, ctrl : CameraViewController) {
            self.ctrl = ctrl
            super.init(sender: sender)
        }
    }
    
    public class TakePicture : Message {}
    
    public class OnPicture : Message {
        
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

public class RemoteCmd : Message {
    
    public class TakePic : RemoteCmd, NSCoding {
        
        public override init(sender: Optional<ActorRef>) {
            super.init(sender: sender)
        }
        
        public func encodeWithCoder(aCoder: NSCoder) {}
        
        public required init?(coder aDecoder: NSCoder) {
            super.init(sender: Optional.None)
        }
        
    }
    
    public class TakePicAck : Message, NSCoding {
        
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
    
    public class SendFrame : Message, NSCoding {
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
    
    public class OnFrame : Message {
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
    
    public class PeerBecameCamera : Message , NSCoding {
        
        public init() {
            super.init(sender : Optional.None)
        }
        
        public func encodeWithCoder(aCoder: NSCoder) {}
        
        public required init?(coder aDecoder: NSCoder) {
            super.init(sender: Optional.None)
        }
    }
    
    public class PeerBecameMonitor : Message , NSCoding {
        
        public init() {
            super.init(sender : Optional.None)
        }
        
        public func encodeWithCoder(aCoder: NSCoder) {}
        
        public required init?(coder aDecoder: NSCoder) {
            super.init(sender: Optional.None)
        }
    }
}



