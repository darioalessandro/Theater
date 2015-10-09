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

public class StartScanningWithLobbyViewController : Message {
    
    public let lobby : LobbyViewController
    
    public init(sender: Optional<ActorRef>, lobby : LobbyViewController) {
        self.lobby = lobby
        super.init(sender: sender)
    }
    
}

public class Disconnect : Message {}

public class ConnectToDevice : Message {
    public let peer : MCPeerID
    
    public init(peer : MCPeerID, sender : Optional<ActorRef>) {
        self.peer = peer
        super.init(sender: sender)
    }
}

public class BecomeDevice : Message {}

public class UnbecomeCamera : Message {}

public class BecomeCamera : BecomeDevice {}

public class UnbecomeMonitor : Message {}

public class BecomeMonitor : BecomeDevice {}

public class DisconnectPeer : OnConnectToDevice{}

public class OnConnectToDevice : ConnectToDevice {}

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
