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
    let peer : MCPeerID
    
    init(peer : MCPeerID, sender : Optional<ActorRef>) {
        self.peer = peer
        super.init(sender: sender)
    }
}

public class BecomeCamera : Message {}

public class BecomeMonitor : Message {}

public class OnConnectToDevice : ConnectToDevice {}

public class SendFrame : Message {
    let data : NSData
    init(data : NSData, sender : Optional<ActorRef>) {
        self.data = data
        super.init(sender: sender)
    }
}

public class OnFrame : Message {
    let data : NSData
    init(data : NSData, sender : Optional<ActorRef>) {
        self.data = data
        super.init(sender: sender)
    }
}