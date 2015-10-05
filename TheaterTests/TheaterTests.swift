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
        
        pong ! TestPerformance(sender: ping, count: 0, max: 2000, expectation: expectation)
        
        self.waitForExpectationsWithTimeout(10) { (error) -> Void in
            print("error \(error)")
        }
    }
    
}
