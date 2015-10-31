//
//  WSViewController.swift
//  Actors
//
//  Created by Dario Lencina on 9/29/15.
//  Copyright © 2015 dario. All rights reserved.
//

import UIKit
import Theater

class WSRViewController : ViewCtrlActor<WSViewController>, UITableViewDataSource, UITableViewDelegate  {
    
    let wsClient : ActorRef
    
    var url : Optional<NSURL> = Optional.None
    
    var receivedMessages : [(String, NSDate)] = [(String, NSDate)]()
    
    required init(context: ActorSystem, ref: ActorRef) {
        self.wsClient = context.actorOf(WebSocketClient)
        super.init(context: context, ref: ref)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.receivedMessages.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("device")!
        let s : (String, NSDate) = self.receivedMessages[indexPath.row]
        cell.textLabel?.text = s.0
        cell.detailTextLabel?.text = s.1.description
        return cell
    }
    
    func connected(ctrl : WSViewController) -> Receive {
        
        return {[unowned self](msg : Message) in
            switch(msg) {
                case let w as WebSocketClient.SendMessage:
                    ^{
                        self.receivedMessages.append(("You: \(w.message)", NSDate.init()))
                        let i = self.receivedMessages.count - 1
                        let lastRow = NSIndexPath.init(forRow: i, inSection: 0)
                        ctrl.tableView.insertRowsAtIndexPaths([lastRow], withRowAnimation: UITableViewRowAnimation.Automatic)
                        ctrl.tableView.scrollToRowAtIndexPath(lastRow, atScrollPosition: UITableViewScrollPosition.Middle, animated: true)
                    }
                    self.wsClient ! WebSocketClient.SendMessage(sender: self.this, message: w.message)
                
                case let w as WebSocketClient.OnMessage:
                    ^{
                        self.receivedMessages.append(("Server: \(w.message)", NSDate.init()))
                        let i = self.receivedMessages.count - 1
                        let lastRow = NSIndexPath.init(forRow: i, inSection: 0)
                        ctrl.tableView.insertRowsAtIndexPaths([lastRow], withRowAnimation: UITableViewRowAnimation.Automatic)
                        ctrl.tableView.scrollToRowAtIndexPath(lastRow, atScrollPosition: UITableViewScrollPosition.Middle, animated: true)
                    }
                    
                case let w as WebSocketClient.OnDisconnect:
                    self.onDisconnect(ctrl, msg : w)
                    
                default:
                    self.receive(msg)
            }
        }
    }
    
    func onDisconnect(ctrl : WSViewController, msg : WebSocketClient.OnDisconnect) -> Void {
        ^{
            ctrl.title = "Disconnected"
            ctrl.navigationItem.prompt = msg.error?.localizedDescription
            self.unbecome()
        }
        
        self.scheduleOnce(1,block: {
            if let url = self.url {
                self.this ! WebSocketClient.Connect(url: url, sender: self.this)
            }
        })
    }
    

     override func withCtrl(ctrl : WSViewController) -> Receive {
        
        ^{
            ctrl.tableView.dataSource = self
            ctrl.tableView.delegate = self
        }
        return {[unowned self] (msg : Message) in
            switch(msg) {
                case let w as WebSocketClient.Connect:
                    self.wsClient ! WebSocketClient.Connect(url: w.url, sender: self.this)
                    self.url = w.url
                    ^{ () in
                        ctrl.title = "Connecting"
                    }
                    break
                    
                case is WebSocketClient.OnConnect:
                    ^{ () in
                        ctrl.title = "Connected"
                        ctrl.navigationItem.prompt = nil
                        ctrl.textField.becomeFirstResponder()
                        self.become("connected", state:self.connected(ctrl))
                    }
                    break
                    
                case is Disconnect:
                    self.wsClient ! Disconnect(sender: self.this)
                
                case let m as WebSocketClient.OnDisconnect:
                    ^{
                        ctrl.title = "Disconnected"
                        ctrl.navigationItem.prompt = m.error?.localizedDescription
                    }
                    self.scheduleOnce(1,block: {
                        if let url = self.url {
                            self.this ! WebSocketClient.Connect(url: url, sender: self.this)
                        }
                    })
                    
                default:
                    ctrl.tableView.dataSource = nil
                    ctrl.tableView.delegate = nil
                    self.receive(msg)
            }
            self.receive(msg)
        }
    }

    
    deinit {
        self.wsClient ! Harakiri(sender: nil)
    }
}

class WSViewController : UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendbar: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var send: UIButton!
    @IBOutlet weak var bottomTextField: NSLayoutConstraint!
    var wsCtrl : ActorRef = AppActorSystem.shared.actorOf(WSRViewController.self, name:  "WSRViewController")
    
    override func viewDidLoad() {
        wsCtrl ! SetViewCtrl(ctrl: self)
        wsCtrl ! WebSocketClient.Connect(url: NSURL(string: "wss://echo.websocket.org")!, sender : nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillAppear:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillDisappear:", name: UIKeyboardWillHideNotification, object: nil)
        send.addTarget(self, action: "onClick:", forControlEvents: .TouchUpInside)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        wsCtrl ! WebSocketClient.SendMessage(sender: nil, message: textField.text!)
        return true
    }
    
    @objc func onClick(btn : UIButton) {
        wsCtrl ! WebSocketClient.SendMessage(sender: nil, message: textField.text!)
    }
    
    internal override func viewWillDisappear(animated: Bool) {
        if(self.isBeingDismissed() || self.isMovingFromParentViewController()){
            wsCtrl ! Harakiri(sender: nil)
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func keyboardWillAppear(notification: NSNotification){
        let userInfo:NSDictionary = notification.userInfo!
        let keyboardSize:CGSize = userInfo.objectForKey(UIKeyboardFrameBeginUserInfoKey)!.CGRectValue.size
        
        bottomTextField.constant = keyboardSize.height;
        self.view.setNeedsUpdateConstraints()
        
        UIView.animateWithDuration(0.25) { () in
            self.view.layoutIfNeeded()
        }
    }
    
    func keyboardWillDisappear(notification: NSNotification){
        bottomTextField.constant = 0;
        self.view.setNeedsUpdateConstraints()
        
        UIView.animateWithDuration(0.25) { () in
            self.view.layoutIfNeeded()
        }
    }
    
    
}