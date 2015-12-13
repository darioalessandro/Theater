//
//  AccountOps.swift
//  Actors
//
//  Created by Dario on 10/5/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Theater

public class SetAccountNumber: Actor.Message {
    
    public let accountNumber : String
    
    public init(accountNumber : String, operationId : NSUUID) {
        self.accountNumber = accountNumber
        super.init(sender: nil)
    }
    
}

public class BankOp: Actor.MessageWithOperationId {
    
    public let ammount : Double
    
    public init(sender: Optional<ActorRef>, ammount : Double, operationId : NSUUID) {
        self.ammount = ammount
        super.init(sender: sender, operationId : operationId)
    }
}

public class Withdraw: BankOp {}

public class Deposit: BankOp {}

public class PrintBalance: Actor.MessageWithOperationId {
    public init(operationId : NSUUID) {
        super.init(sender: nil, operationId : operationId)
    }
}

public class BankOpResult : Actor.Message {
    
    public let result : Try<Double>
    
    public let operationId : NSUUID
    
    public init(sender : ActorRef, operationId : NSUUID, result : Try<Double>) {
        self.operationId = operationId
        self.result = result
        super.init(sender: sender)
    }
}

public class WithdrawResult : BankOpResult { }

public class DepositResult : BankOpResult { }

public class OnBalanceChanged : Actor.Message {
    public let balance : Double
    public init(sender : ActorRef, balance : Double) {
        self.balance = balance
        super.init(sender: sender)
    }
}

public class Transfer : BankOp {
    let origin : ActorRef
    let destination : ActorRef
    init(origin : ActorRef, destination : ActorRef,
        sender : ActorRef, ammount : Double) {
            self.origin = origin
            self.destination = destination
            super.init(sender: sender, ammount: ammount, operationId: NSUUID())
    }
}

public class TransferResult : BankOpResult {}