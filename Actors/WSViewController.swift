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
    
    struct States {
        let connecting = "Connecting"
        let connected = "Connected"
        let disconnected = "Disconnected"
    }
    
    let states = States()
    
    lazy var wsClient : ActorRef = self.actorOf(WebSocketClient.self, name:"WebSocketClient")
    
    var receivedMessages : [(String, NSDate)] = [(String, NSDate)]()
    
    // MARK: UITableView related methods
    
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
    
    // MARK: Actor states
    
    override func receiveWithCtrl(ctrl : WSViewController) -> Receive {
        ^{
            ctrl.tableView.dataSource = self
            ctrl.tableView.delegate = self
        }
        return {[unowned self] (msg : Actor.Message) in
            switch(msg) {
            case is WebSocketClient.Connect:
                self.become(self.states.disconnected, state: self.disconnected(ctrl))
                self.this ! msg
                
            default:
                ctrl.tableView.dataSource = nil
                ctrl.tableView.delegate = nil
                self.receive(msg)
            }
        }
    }
    
    func disconnected(ctrl : WSViewController) -> Receive {
        return {[unowned self] (msg : Actor.Message) in
            switch(msg) {
            case let w as WebSocketClient.Connect:
                self.become(self.states.connecting, state: self.connecting(ctrl, url:w.url,  headers : w.headers))
                self.wsClient ! WebSocketClient.Connect(url: w.url, headers: w.headers, sender: self.this)
                ^{ ctrl.title = "Connecting"}
                
            case let m as WebSocketClient.OnDisconnect:
                ^{ctrl.title = "Disconnected"
                 ctrl.navigationItem.prompt = m.error?.localizedDescription}
                
            default:
                self.receive(msg)
            }
        }
    }
    
    func connecting(ctrl : WSViewController, url : NSURL, headers : Dictionary<String,String>?) -> Receive {
        return {[unowned self] (msg : Actor.Message) in
            switch(msg) {
                
            case is WebSocketClient.OnConnect:
                ^{ctrl.title = "Connected"
                  ctrl.navigationItem.prompt = nil
                  ctrl.textField.becomeFirstResponder()}
                self.become(self.states.connected, state:self.connected(ctrl, url: url, headers: headers))
                
            case let m as WebSocketClient.OnDisconnect:
                self.unbecome()
                self.this ! m

                self.scheduleOnce(1,block: {
                    self.this ! WebSocketClient.Connect(url: url, headers: headers, sender: self.this)
                })
            
            default:
                self.receive(msg)
            }
        
        }
    }
    
    func connected(ctrl : WSViewController, url : NSURL, headers : Dictionary<String,String>?) -> Receive {
        
        return {[unowned self](msg : Actor.Message) in
            switch(msg) {
                case let w as WebSocketClient.SendMessage:
                    self.receivedMessages.append(("You: \(w.message)", NSDate.init()))
                    let i = self.receivedMessages.count - 1
                    ^{
                      let lastRow = NSIndexPath.init(forRow: i, inSection: 0)
                      ctrl.tableView.insertRowsAtIndexPaths([lastRow], withRowAnimation: UITableViewRowAnimation.Automatic)
                      ctrl.tableView.scrollToRowAtIndexPath(lastRow, atScrollPosition: UITableViewScrollPosition.Middle, animated: true)}
                    self.wsClient ! WebSocketClient.SendMessage(sender: self.this, message: w.message)
                
                case let w as WebSocketClient.OnMessage:
                    self.receivedMessages.append(("Server: \(w.message)", NSDate.init()))
                    let i = self.receivedMessages.count - 1
                    ^{
                      let lastRow = NSIndexPath.init(forRow: i, inSection: 0)
                      ctrl.tableView.insertRowsAtIndexPaths([lastRow], withRowAnimation: UITableViewRowAnimation.Automatic)
                      ctrl.tableView.scrollToRowAtIndexPath(lastRow, atScrollPosition: UITableViewScrollPosition.Middle, animated: true)}
                    
                case let m as WebSocketClient.OnDisconnect:
                    self.popToState(self.states.disconnected)
                    self.this ! m
                    self.scheduleOnce(1,block: {
                        self.this ! WebSocketClient.Connect(url: url, headers : headers, sender: self.this)
                    })
                    
                default:
                    self.receive(msg)
            }
        }
    }

    required init(context: ActorSystem, ref: ActorRef) {
        super.init(context: context, ref: ref)
    }
    
    /**
    Cleanup resources, in this case, destroy the wsClient ActorRef
    */
    
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
    
    lazy var system : ActorSystem = ActorSystem(name:"WS")
    
    lazy var wsCtrl : ActorRef = self.system.actorOf(WSRViewController.self, name:  "WSRViewController")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        wsCtrl ! SetViewCtrl(ctrl: self)
        wsCtrl ! WebSocketClient.Connect(url: NSURL(string: "http://localhost:9000")!, headers: ["tina":"coneja"], sender : nil)
        self.addNotifications()
        send.addTarget(self, action: "onClick:", forControlEvents: .TouchUpInside)
    }
    
    override func viewWillDisappear(animated: Bool) {
        if self.isBeingDismissed() || self.isMovingFromParentViewController() {
            system.stop()
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func addNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillAppear:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillDisappear:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        wsCtrl ! WebSocketClient.SendMessage(sender: nil, message: textField.text!)
        return true
    }
    
    @objc func onClick(btn : UIButton) {
        wsCtrl ! WebSocketClient.SendMessage(sender: nil, message: textField.text!)
    }
    
    func keyboardWillAppear(notification: NSNotification){
        let userInfo:NSDictionary = notification.userInfo!
        let keyboardSize:CGSize = userInfo.objectForKey(UIKeyboardFrameBeginUserInfoKey)!.CGRectValue.size
        
        bottomTextField.constant = keyboardSize.height;
        self.view.setNeedsUpdateConstraints()
        
        UIView.animateWithDuration(0.25) {
            self.view.layoutIfNeeded()
        }
    }
    
    func keyboardWillDisappear(notification: NSNotification){
        bottomTextField.constant = 0;
        self.view.setNeedsUpdateConstraints()
        
        UIView.animateWithDuration(0.25) {
            self.view.layoutIfNeeded()
        }
    }
    
    
}