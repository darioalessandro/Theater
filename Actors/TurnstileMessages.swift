//
//  TurnstileMessages.swift
//  Actors
//
//  Created by Dario Lencina on 11/7/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Theater

extension CoinModule {
    
    class InsertCoin : Actor.Message {}
    
}

extension Gate {
    
    class Push : Actor.Message {}
    
    class Unlock : Actor.Message {}
    
}