//
//  AppActorSystem.swift
//  Actors
//
//  Created by Dario Lencina on 9/27/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation

/**
 Convenience actor system for apps so that you can reference it anywhere in your app
*/

public class AppActorSystem : ActorSystem {
    
    /**
     Convenience actor system for apps so that you can reference it anywhere in your app
    */
    
    public static let shared : AppActorSystem = AppActorSystem(name: "AppActorSystem")
    
    /**
    Hidden constructor so that it is not possible to create more AppActorSystems
    */
    
    override private init(name: String) {
        super.init(name: name)
    }
}