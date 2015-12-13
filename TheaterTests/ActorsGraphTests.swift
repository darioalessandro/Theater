//
//  ActorsGraphTst.swift
//  Actors
//
//  Created by Dario Lencina on 12/12/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Theater

class ActorGraphTests: QuickSpec {
    
    override func spec() {
        
        describe("Crowd test system") {
            describe("11") {
                it("should create a 2 level system with 3 children on each node") {
                    print("")
                    expect(4).to(beIdenticalTo(5))
                }
            }

        }
    }

}