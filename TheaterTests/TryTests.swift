//
//  TryTests.swift
//  Actors
//
//  Created by Dario on 10/5/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import XCTest
import Theater

public class TryGenerator {
    private let n : Int
    
    public init(n : Int) {
        self.n = n
    }
    
    public func isItBiggerThan3() -> Try<Int>  {
        if self.n > 3 {
            return Success(value: self.n)
        } else {
            return Failure(exception: NSError(domain: "No it is not", code: 0, userInfo: nil))
        }
    }
    
}

class TryTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testFailure() {
        let isItBigger : Try<Int> = TryGenerator(n: 2).isItBiggerThan3()
        XCTAssertEqual(isItBigger.isSuccess(), false)
    }
    
    func testSuccess() {
        let isItBigger : Try<Int> = TryGenerator(n: 4).isItBiggerThan3()
        XCTAssertEqual(isItBigger.isSuccess(), true)
    }
    
    func testMappingOnFailure() {
        let isItBigger : Try<Int> = TryGenerator(n: 2).isItBiggerThan3()
        let result = isItBigger.map { (nn : Int) -> Int in
            return nn + 3
        }
        
        XCTAssertEqual(result.isFailure(), true)
    }
    
    func testMappingOnSuccess() {
        let isItBigger : Try<Int> = TryGenerator(n: 4).isItBiggerThan3()
        let result = isItBigger.map { (nn : Int) -> Int in
            return nn + 3
        }
        
        XCTAssertEqual(result.isSuccess(), true)
        XCTAssertEqual(result.get(), 7)
    }
    
    func testConcatenation() {
        let computation1 : Try<Int> = TryGenerator(n: 4).isItBiggerThan3()
        let computation2 : Try<Int> = TryGenerator(n: 4).isItBiggerThan3()
        let computation3 : Try<Int> = TryGenerator(n: 2).isItBiggerThan3()
        
        if let c1 = computation1.hasValue(), c2 = computation2.hasValue(), c3 = computation3.hasValue() {
            XCTAssertTrue(false, "\(c1), \(c2) \(c3)")
        } else {
            XCTAssertTrue(true)
        }
        
        if let c1 = computation1.hasValue(), c2 = computation2.hasValue() {
            XCTAssertTrue(true, "\(c1), \(c2)")
        } else {
             XCTAssertTrue(false)
        }
        
    }
    
}
