//
//  BLEPeripheral.swift
//  Actors
//
//  Created by Dario Lencina on 10/14/15.
//  Copyright © 2015 dario. All rights reserved.
//

import Foundation
import CoreBluetooth

public class BLEPeripheralObservation {

    public let peripheral: CBPeripheral
    public let advertisementData: [String : AnyObject]
    public let RSSI: NSNumber
    public let timestamp : NSDate
    
    init(peripheral: CBPeripheral,advertisementData: [String : AnyObject],RSSI: NSNumber,timestamp : NSDate) {
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.RSSI = RSSI
        self.timestamp = timestamp
    }
}