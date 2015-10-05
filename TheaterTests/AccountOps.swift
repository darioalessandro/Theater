//
//  AccountOps.swift
//  Actors
//
//  Created by Dario on 10/5/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Theater

public class BankOp: MessageWithOperationId {
    
    public let ammount : Double
    
    public init(sender: Optional<ActorRef>, ammount : Double, operationId : NSUUID) {
        self.ammount = ammount
        super.init(sender: sender, operationId : operationId)
    }
}

public class SetAccountNumber: Message {
    
    public let accountNumber : String
    
    public init(accountNumber : String, operationId : NSUUID) {
        self.accountNumber = accountNumber
        super.init(sender: Optional.None)
    }
    
}

public class Withdraw: BankOp {}

public class Deposit: BankOp {}

public class PrintBalance: MessageWithOperationId {
    public init(operationId : NSUUID) {
        super.init(sender: Optional.None, operationId : operationId)
    }
}

public class BankOpResult : Message {
    
    public let result : Try<Double>
    
    public let operationId : NSUUID
    
    public init(sender : ActorRef, operationId : NSUUID, result : Try<Double>) {
        self.operationId = operationId
        self.result = result
        super.init(sender: sender)
    }
}