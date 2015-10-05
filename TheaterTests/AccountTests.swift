//
//  AccountTests.swift
//  Actors
//
//  Created by Dario on 10/5/15.
//  Copyright © 2015 dario. All rights reserved.
//

import XCTest
import Theater
@testable import Theater

class AccountTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testDepositAndWithdrawal() {
        let expectation = expectationWithDescription("Swift Expectations")
        let system = TestActorSystem(name: "testActorSystem")
        
        let acc1Ref = system.actorOf(Account)
        let acc2Ref = system.actorOf(Account)
        let acc3Ref = system.actorOf(Account)
        
        acc1Ref ! Deposit(sender: Optional.None, ammount : 1000, operationId: NSUUID())
        acc2Ref ! Deposit(sender: Optional.None, ammount : 2000, operationId: NSUUID())
        acc3Ref ! Deposit(sender: Optional.None, ammount : 3000, operationId: NSUUID())
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
        
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            acc1Ref ! Withdraw(sender: acc2Ref, ammount:1000, operationId: NSUUID())
            acc3Ref ! Withdraw(sender: acc2Ref, ammount:1000, operationId: NSUUID())
        }
        
        let delayTime2 = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime2, dispatch_get_main_queue()) {
            
            let acc1 : Account = system.actorForRef(acc1Ref) as! Account
            let acc2 : Account = system.actorForRef(acc2Ref) as! Account
            let acc3 : Account = system.actorForRef(acc3Ref) as! Account
            
            if let a1b = acc1.balance().toOptional(), a2b = acc2.balance().toOptional(), a3b = acc3.balance().toOptional() {
                XCTAssertEqual(a1b, 0000)
                XCTAssertEqual(a2b, 4000)
                XCTAssertEqual(a3b, 2000)
            } else {
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(10) { (error) -> Void in
            print("error \(error)")
        }
    }
    
}