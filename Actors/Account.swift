//
//  AccountsDemo.swift
//  Actors
//
//  Created by Dario Lencina on 9/26/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Theater


public class Account : Actor {
    
    func delay() -> Double {
        return Double(arc4random_uniform(5))
    }
    
    
    override public var description  : String {
        return " \(self.balance())"
    }
    
    var number : String = ""
    
    private var _balance : Double = 0 {
        
        didSet {
            if _balance != oldValue {
                if let sender = sender {
                    sender ! OnBalanceChanged(sender: this, balance:_balance)
                }
            }
        }
        
    }
    
    public override func receive(msg: Message) {
        switch msg {
            
            case is SetAccountNumber:
                let w = msg as! SetAccountNumber
                self.number = w.accountNumber
                print("account number \(self.number)")
                break;
            case is Withdraw:
                let w = msg as! Withdraw
                let op = self.withdraw(w.ammount)
                if let sender = self.sender {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay() * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                        sender ! WithdrawResult(sender: self.this, operationId: w.operationId, result: op)
                    })
                }
                break;
            case is Deposit:
                let w = msg as! Deposit
                let r = self.deposit(w.ammount)
                if let sender = self.sender {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay() * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                        sender ! DepositResult(sender: self.this, operationId: w.operationId, result: r)
                    })
                }
                
                break;
            case is PrintBalance:
                print("Balance of \(number) is \(balance().get())")
                break;
            
            case is WithdrawResult:
                let w = msg as! WithdrawResult
                if let ammount = w.result.toOptional() {
                    self.deposit(ammount)
                }
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

