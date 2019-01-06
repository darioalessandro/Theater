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

enum NotLarger: Error {
    case than(Int)
}

public class TryGenerator {
    private let n : Int
    
    public init(n : Int) {
        self.n = n
    }
    
    public func isItBiggerThan3() -> Try<Int>  {
        if self.n > 3 {
            return Success(value: self.n)
        } else {
            return Failure(error: NotLarger.than(3))
        }
    }
    
}

class TryTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
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
        let number1Try : Try<Int> = TryGenerator(n: 4).isItBiggerThan3()
        let number2Try : Try<Int> = TryGenerator(n: 4).isItBiggerThan3()
        let number3Try : Try<Int> = TryGenerator(n: 2).isItBiggerThan3()
        
        if let  n1 = number1Try.toOptional(),
                let n2 = number2Try.toOptional(),
                let n3 = number3Try.toOptional() {
            XCTAssertTrue(false, "\(n1), \(n2) \(n3)")
        } else {
            XCTAssertTrue(true)
        }
        
        if let  op1 = TryGenerator(n: 5).isItBiggerThan3().toOptional(),
                let n2 = TryGenerator(n: op1 - 1).isItBiggerThan3().toOptional() {
            XCTAssertEqual(n2, 4)
        } else {
             XCTAssertTrue(false)
        }
    }
    
    
    func testGetOrElse() {
        
        let elseClojure : () -> (Int) = {() -> Int in return 10 * 4}
        
        let number1Try : Int = TryGenerator(n: 2).isItBiggerThan3().getOrElse {elseClojure()}
        XCTAssertEqual(number1Try, 40)
        
        let number2Try : Int = TryGenerator(n: 5).isItBiggerThan3().getOrElse {elseClojure()}
        XCTAssertEqual(number2Try, 5)
    }
}
