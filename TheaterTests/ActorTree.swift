//
//  ActorTree.swift
//  Actors
//
//  Created by Dario Lencina on 12/12/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Theater

class ActorTreeGuy: Actor {
    
    class CreateChildren : Message {
        let count : Int
        
        init(count : Int, sender: Optional<ActorRef>) {
            self.count = count
            super.init(sender: sender)
        }
    }
    
    override func receive(msg: Actor.Message) {
        switch (msg) {
            case let m as CreateChildren:
                for _ in 1...m.count {
                    self.actorOf(clz: ActorTreeGuy.self)
                }
        default:
            super.receive(msg: msg)
        }
    }
}

class ActorTree: QuickSpec {
    
    override func spec() {

        describe("ActorTree2") {
            let system  = TestActorSystem(name: "ActorTree")
            it("Create 10 actors") {
                let root = system.actorOf(clz: ActorTreeGuy.self)
                    root ! ActorTreeGuy.CreateChildren(count:4, sender:nil)
                
                let root2 = system.actorOf(clz: ActorTreeGuy.self)
                    root2 ! ActorTreeGuy.CreateChildren(count:19, sender:nil)
                if let r = system.actorForRef(ref: root) {                    expect(r.getChildrenActors().count).toEventually(equal(Int(4)), timeout: 10, pollInterval: 1, description: "Unable to create children")
                }
                if let r = system.actorForRef(ref: root2) {                    expect(r.getChildrenActors().count).toEventually(equal(Int(19)), timeout: 10, pollInterval: 1, description: "Unable to create children")
                }
            }
        
            
            it ("should stop when required"){
                system.stop()
                
                expect(system.selectActor(actorPath: "ActorTree/user")).toEventually(beNil(), timeout: 10, pollInterval: 1, description: "Unable to create children")
            }
        }
    }
}
