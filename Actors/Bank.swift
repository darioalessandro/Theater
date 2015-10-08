//
//  Bank.swift
//  Actors
//
//  Created by Dario on 10/6/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Theater

public class Bank : Actor {

    let accountA : ActorRef = AppActorSystem.shared.actorOf(Account.self, name: "AccountA")
    let accountB : ActorRef = AppActorSystem.shared.actorOf(Account.self, name: "AccountB")
    
    var accountALabel : Optional<UILabel> = Optional.None
    var accountBLabel : Optional<UILabel> = Optional.None
    
    public var transfers : [String:(Transfer, Optional<TransferResult>)] = [String : (Transfer, Optional<TransferResult>)]()
    
    @objc func onClickBtoA(click: UIButton) {
        this ! Transfer(origin: accountB, destination: accountA, sender: this, ammount: 1)
    }
    
    @objc func onClickAtoB(click: UIButton) {
        this ! Transfer(origin: accountA, destination: accountB, sender: this, ammount: 1)
    }
    
    override public func receive(msg: Message) {
        switch(msg) {
            case let w as Transfer:
            if self.transfers.keys.contains(w.operationId.UUIDString) == false {
                self.transfers[w.operationId.UUIDString] = (w,Optional.None)
                let wireTransfer = context.actorOf(WireTransferWorker.self, name:"WorkerId\(w.operationId.UUIDString)") //TODO: We need to add timeout
                wireTransfer ! w
            }
            break
            
            case let w as TransferResult:
            let uuid = w.operationId.UUIDString
            if let transfer = self.transfers[uuid] {
                self.transfers[uuid] = (transfer.0, w)
            }
            
            if w.result.isFailure() { ^{
                    let v = self.transfers[uuid]!
                    UIAlertView(title: "Transaction error from:\(v.0.origin.path.asString) to:\(v.0.destination.path.asString)", message: "\(w.result.description())", delegate: nil, cancelButtonTitle: "ok").show()
                }
            }
            
            w.sender! ! Harakiri(sender: this)
            break
            
            case let w as HookupViewController:
            ^{
                w.ctrl.bToA.addTarget(self, action: "onClickBtoA:", forControlEvents: .TouchUpInside)
                w.ctrl.aToB.addTarget(self, action: "onClickAtoB:", forControlEvents: .TouchUpInside)
                self.accountALabel = w.ctrl.accountABalance
                self.accountBLabel = w.ctrl.accountBBalance
            }
            
            accountA ! SetAccountNumber(accountNumber: "AccountA", operationId: NSUUID())
            accountB ! SetAccountNumber(accountNumber: "AccountB", operationId: NSUUID())
            
            print("accountA \(accountA.path.asString)")
            print("accountB \(accountB.path.asString)")
            
            accountA ! Deposit(sender: this, ammount: 10, operationId: NSUUID())
            accountB ! Deposit(sender: this, ammount: 10, operationId: NSUUID())
            break
            
            case let w as OnBalanceChanged:
            ^{
                if let account : ActorRef = w.sender {
                    print("account.path.asString \(account.path.asString)" )
                    switch (account.path.asString) {
                    case self.accountA.path.asString:
                        self.accountALabel?.text = w.balance.description
                        break
                    case self.accountB.path.asString:
                        self.accountBLabel?.text = w.balance.description
                        break
                    default:
                        print("account not found \(account.path.asString)")
                        
                    }
                }
                
            }
            
            break
        default:
            super.receive(msg)
        }
        
    }
}
