//
//  AccountsDemo.swift
//  Actors
//
//  Created by Dario Lencina on 9/26/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Theater

public class BankOp: Message {
    
    public let ammount : Double
    
    public let operationId : NSUUID
    
    public init(sender: Actor, ammount : Double, operationId : NSUUID) {
        self.ammount = ammount
        self.operationId = operationId
        super.init(sender: sender)
    }
    
}

public class Withdraw: BankOp {}

public class Deposit: BankOp {}

public class Balance: BankOp {}

public class BankOpResult : Message {
    
    public let result : Try<Double>
    public let operationId : NSUUID
    
    public init(sender : Actor, operationId : NSUUID, result : Try<Double>) {
        self.operationId = operationId
        self.result = result
        super.init(sender: sender)
    }
}

public class Account : Actor {
    
    public func description() -> NSString {
        return " \(self.balance())"
    }
    
    public let number : String
    
    public init(number : String) {
        self.number = number
        super.init()
    }
    
    private var _balance : Double = 0
    
    public override func receive(msg: Message) {
        switch msg {
            case is Withdraw:
                let w = msg as! Withdraw
                self.sender!.send(BankOpResult(sender: self, operationId: w.operationId, result: self.withdraw(w.ammount)))
                break;
            case is Deposit:
                let w = msg as! Deposit
                self.sender!.send(BankOpResult(sender: self, operationId: w.operationId, result: self.deposit(w.ammount)))
                break;
            case is Balance:
                let w = msg as! Balance
                self.sender!.send(BankOpResult(sender: self, operationId: w.operationId, result: self.balance()))
                break;
            case is BankOpResult:
                let w = msg as! BankOpResult
                print("Account \(number) : \(w.operationId.UUIDString) \(w.result.description())")
                break;
            default:
                print("Unable to handle message")
        }
    }
    
    func withdraw(amount : Double) -> Try<Double> {
        if _balance >= amount {
            _balance = _balance - amount
            return Success(value : _balance)
        } else {
            return Failure(exception: NSError(domain: "Insufficient funds", code: 0, userInfo: nil))
        }
        
    }
    
    func deposit(amount : Double) -> Try<Double> {
        _balance = _balance + amount
        return Success(value : _balance)
    }
    
    func balance() -> Try<Double> {
        return Success(value: _balance)
    }
}

