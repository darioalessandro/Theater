//
//  WireTransferWorker.swift
//  Actors
//
//  Created by Dario on 10/6/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Theater

public class WireTransferWorker : Actor {
    
    var transfer : Optional<Transfer> = Optional.None
    var bank : Optional<ActorRef> = Optional.None
    
    
    lazy var transfering : Receive = {[unowned self](msg : Message) in
        switch(msg) {
        case is WithdrawResult:
            let w : WithdrawResult = msg as! WithdrawResult
            if w.result.isSuccess() {
                self.transfer!.destination ! Deposit(sender: self.this, ammount: self.transfer!.ammount, operationId: NSUUID())
            } else {
                self.bank! ! TransferResult(sender: self.this, operationId: self.transfer!.operationId, result: w.result)
                self.unbecome()
            }
            break
            
        case is DepositResult:
            let w : DepositResult = msg as! DepositResult
            self.bank! ! TransferResult(sender: self.this, operationId: self.transfer!.operationId, result: w.result)
            self.unbecome()
            break
            
        case is OnBalanceChanged:
            if let _ = self.transfer {self.bank! ! msg }
            break
            
        default:
            print("busy, go away")
        }
    }
    
    override public func receive(msg: Message) {
        switch (msg) {
        case is Transfer:
            if let _ = self.transfer {} else {
                self.transfer = Optional.Some(msg as! Transfer)
                self.bank = self.transfer!.sender
                become(transfering)
                if let transfer = self.transfer {
                    transfer.origin ! Withdraw(sender: this, ammount: transfer.ammount, operationId: NSUUID())
                }
            }
            break
            
        default:
            super.receive(msg)
        }
    }
}