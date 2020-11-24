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

    class CreateChildren: Message {
        let count: Int

        init(count: Int, sender: ActorRef?) {
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
            let system = TestActorSystem(name: "ActorTree")
            it("Create 10 actors") {
                let guy1 = system.actorOf(clz: ActorTreeGuy.self, name: "ActorTreeGuy1")!
                guy1 ! ActorTreeGuy.CreateChildren(count: 4, sender: nil)

                let guy2 = system.actorOf(clz: ActorTreeGuy.self, name: "ActorTreeGuy2")!
                guy2 ! ActorTreeGuy.CreateChildren(count: 19, sender: nil)
                
                if let r = system.actorForRef(ref: guy1) {
                    expect(r.getChildrenActors().count).toEventually(equal(Int(4)), timeout: 10, pollInterval: 1, description: "Unable to create children")
                }
                if let r = system.actorForRef(ref: guy2) {
                    expect(r.getChildrenActors().count).toEventually(equal(Int(19)), timeout: 10, pollInterval: 1, description: "Unable to create children")
                }
            }


            it("should stop when required") {
                system.stop()
                expect(system.selectActor(actorPath: "ActorTree/user")).toEventually(beNil(), timeout: 10, pollInterval: 1, description: "Unable to create children")
            }
        }
    }
}
