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

public class BecomeDevice : Message {
    
}

public class BecomeCamera : BecomeDevice {}

public class BecomeMonitor : BecomeDevice {}

public class OnConnectToDevice : ConnectToDevice {}

public class SendFrame : Message {
    public let data : NSData
    init(data : NSData, sender : Optional<ActorRef>) {
        self.data = data
        super.init(sender: sender)
    }
}

public class OnFrame : Message {
    public let data : NSData
    public let peerId : MCPeerID
    
    init(data : NSData, sender : Optional<ActorRef>, peerId : MCPeerID) {
        self.data = data
        self.peerId = peerId
        super.init(sender: sender)
    }
}
