//
//  AppDelegate.swift
//  Actors
//
//  Created by Dario Lencina on 9/26/15.
//  Copyright © 2015 dario. All rights reserved.
//

import UIKit
import Theater


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var opqueue = NSOperationQueue()
    
    var system = ActorSystem(name : "system")
    


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        let rich : Try<ActorRef> = system.actorOf(Account)
        let ac1 : Try<ActorRef> = system.actorOf(Account)
        let ac2 : Try<ActorRef> = system.actorOf(Account)
        let ac3 : Try<ActorRef> = system.actorOf(Account)
        
        if ac1.isSuccess() && ac2.isSuccess() && ac3.isSuccess() && rich.isSuccess() {
            let accountA = ac1.get()
            let accountB = ac2.get()
            let accountC = ac3.get()
            let rico = rich.get()
            
            system.tell(SetAccountNumber(accountNumber: "accountA", operationId: NSUUID.init()), recipient: accountA)
            system.tell(SetAccountNumber(accountNumber: "accountB", operationId: NSUUID.init()), recipient: accountB)
            system.tell(SetAccountNumber(accountNumber: "accountC", operationId: NSUUID.init()), recipient: accountC)
            system.tell(SetAccountNumber(accountNumber: "rico", operationId: NSUUID.init()), recipient: rico)
            
            opqueue.addOperationWithBlock { () -> Void in
                print("1")
                accountA.tell(Deposit(sender: rico, ammount: 100, operationId: NSUUID.init()))
                accountA.tell(PrintBalance(operationId: NSUUID.init()))
                accountA.tell(Deposit(sender: rico, ammount: 100, operationId: NSUUID.init()))
                accountA.tell(PrintBalance(operationId: NSUUID.init()))
            }
            /*opqueue.addOperationWithBlock { () -> Void in
                print("2")
                accountB.tell(Deposit(sender: rico, ammount: 100, operationId: NSUUID.init()))
            }
            opqueue.addOperationWithBlock { () -> Void in
                NSThread.sleepForTimeInterval(0.2)
                print("3")
                accountC.tell(Deposit(sender: rico, ammount: 100, operationId: NSUUID.init()))
            }
            opqueue.addOperationWithBlock { () -> Void in
                NSThread.sleepForTimeInterval(1)
                print("4")
                accountC.tell(Withdraw(sender: rico, ammount: 53, operationId: NSUUID.init()))
            }
            opqueue.addOperationWithBlock { () -> Void in
                print("5")
                accountC.tell(Withdraw(sender: rico, ammount: 33, operationId: NSUUID.init()))
            }
            opqueue.addOperationWithBlock { () -> Void in
                print("6")
                accountC.tell(Withdraw(sender: rico, ammount: 51, operationId: NSUUID.init()))
            }
            opqueue.addOperationWithBlock { () -> Void in
                print("7")
                accountC.tell(Withdraw(sender: rico, ammount: 33, operationId: NSUUID.init()))
            }*/
            
        } else {
            
        }
        
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

