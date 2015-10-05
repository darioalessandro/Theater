//
//  TestActor.swift
//  Actors
//
//  Created by Dario on 10/5/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import Theater

public class TestActor2 {
    
    public class func t(type : Actor.Type, system : TestActorSystem) -> Optional<Actor> {
        let ref = system.actorOf(type)
        return system.actorForRef(ref)
    }
    
}