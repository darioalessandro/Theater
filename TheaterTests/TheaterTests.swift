//
//  TheaterTests.swift
//  TheaterTests
//
//  Created by Dario Lencina on 9/26/15.
//  Copyright © 2015 dario. All rights reserved.
//

import XCTest
import Theater
@testable import Theater

public class ChrisRedfield : Actor {
    
    
    public required init(context: ActorSystem, ref: ActorRef) {
        super.init(context: context, ref: ref)
    }
    
    var expectation : XCTestExpectation!
    
    public class SetExpectation : Message {
        internal let expectation : XCTestExpectation
        
        init(expectation : XCTestExpectation) {
            self.expectation = expectation
            super.init(sender: Optional.None)
        }
    }
    
    override public func receive(msg: Message) {
        switch(msg) {
        case let e as SetExpectation:
            self.expectation = e.expectation
            
        case is DeadLetter:
            XCTAssert(true)
            expectation.fulfill()
            
        default:
            XCTAssert(false)
        }
    }
}

class TheaterTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTestSending2000Msg() {
        let expectation = expectationWithDescription("Swift Expectations")
        let system = AppActorSystem.shared
        
        let ping = system.actorOf(TestActor)
        let pong = system.actorOf(TestActor)
        
        pong ! TestPerformance(sender: ping, count: 0, max: 10, expectation: expectation)
        
        self.waitForExpectationsWithTimeout(10) { (error) -> Void in
            print("error \(error)")
        }
    }
    
    
    func testThatDeadLettersAreGeneratedWhenTryingToReachADeathActor() {
        let expectation = expectationWithDescription("Swift Expectations")
        let system = AppActorSystem.shared
        
        let medium = system.actorOf(ChrisRedfield.self, name: "Medium")
        let zombie = system.actorOf(Actor.self, name: "Zombie")
        
        medium ! ChrisRedfield.SetExpectation(expectation: expectation)
        system.stop(zombie)
        zombie ! Message(sender: medium)
        
        self.waitForExpectationsWithTimeout(2) { (error) -> Void in
            print("error \(error)")
        }
    }
    
}
