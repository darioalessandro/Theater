//
//  AppActorSystem.swift
//  Actors
//
//  Created by Dario Lencina on 9/27/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation


public class AppActorSystem : ActorSystem {
    public static let shared : AppActorSystem = AppActorSystem(name: "AppActorSystem")
    override private init(name: String) {
        super.init(name: name)
    }
}