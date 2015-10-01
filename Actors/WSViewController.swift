//
//  WSViewController.swift
//  Actors
//
//  Created by Dario Lencina on 9/29/15.
//  Copyright © 2015 dario. All rights reserved.
//

import UIKit
import Theater

public class SetWSController: Message {
    
    let ctrl : WSViewController
    
    init(ctrl : WSViewController) {
        self.ctrl = ctrl
        super.init(sender : Optional.None)
    }
}

public class WSRViewController : Actor, UITableViewDataSource, UITableViewDelegate  {
    
    let wsClient : ActorRef
    
    weak var ctrl : Optional<WSViewController> = Optional.None
    
    var receivedMessages : [(String, NSDate)] = [(String, NSDate)]()
    
    public required init(context: ActorSystem, ref: ActorRef) {
        self.wsClient = context.actorOf(WebSocketClient)
        super.init(context: context, ref: ref)
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.receivedMessages.count
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("device")!
        let s : (String, NSDate) = self.receivedMessages[indexPath.row]
        cell.textLabel?.text = s.0
        cell.detailTextLabel?.text = s.1.description
        return cell
    }

    override public func receive(msg: Message) {
        switch(msg) {
        case is Connect:
            let w = msg as! Connect
            wsClient ! Connect(url: w.url, delegate: this)
            break;
            
        case is OnConnect:
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                self.ctrl?.title = "Connected"
                self.ctrl?.textField.becomeFirstResponder()
            })
            break;
            
        case is SendMessage:
            let w = msg as! SendMessage
            wsClient ! SendMessage(sender: this, message: w.message)
            break;
            
        case is OnMessage:
            let w = msg as! OnMessage
            self.receivedMessages.append((w.message, NSDate.init()))
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                let i = self.receivedMessages.count - 1
                let lastRow = NSIndexPath.init(forRow: i, inSection: 0)
                self.ctrl?.tableView.insertRowsAtIndexPaths([lastRow], withRowAnimation: UITableViewRowAnimation.Automatic)
                self.ctrl?.tableView.scrollToRowAtIndexPath(lastRow, atScrollPosition: UITableViewScrollPosition.Middle, animated: true)
            })
            break;
            
        case is Disconnect:
            wsClient ! Disconnect(sender: this)
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                self.ctrl?.title = "Disconnected"
            })
            break;
            
        case is SetWSController:
            let w = msg as! SetWSController
            ctrl = w.ctrl
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                self.ctrl?.tableView.dataSource = self
                self.ctrl?.tableView.delegate = self
            })
            break;
            
        default:
            super.receive(msg)
        }
    }
    
    deinit {
        self.wsClient ! Harakiri(sender: Optional.None)
    }
}

class WSViewController : UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendbar: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var send: UIButton!
    @IBOutlet weak var bottomTextField: NSLayoutConstraint!
    var wsCtrl : ActorRef = AppActorSystem.shared.actorOf(WSRViewController)
    
    override func viewDidLoad() {
        wsCtrl ! SetWSController(ctrl: self)
        wsCtrl ! Connect(url: NSURL(string: "wss://echo.websocket.org")!, delegate: wsCtrl)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillAppear:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillDisappear:", name: UIKeyboardWillHideNotification, object: nil)
        send.addTarget(self, action: "onClick:", forControlEvents: .TouchUpInside)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        wsCtrl ! SendMessage(sender: wsCtrl, message: textField.text!)
        return true
    }
    
    @objc func onClick(btn : UIButton) {
        wsCtrl ! SendMessage(sender: wsCtrl, message: textField.text!)
    }
    
    deinit {
        wsCtrl ! Harakiri(sender: Optional.None)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func keyboardWillAppear(notification: NSNotification){
        let userInfo:NSDictionary = notification.userInfo!
        let keyboardSize:CGSize = userInfo.objectForKey(UIKeyboardFrameBeginUserInfoKey)!.CGRectValue.size
        
        
        bottomTextField.constant = keyboardSize.height;
        self.view.setNeedsUpdateConstraints()
        
        UIView.animateWithDuration(0.25) { () -> Void in
            self.view.layoutIfNeeded()
        }
    }
    
    func keyboardWillDisappear(notification: NSNotification){
        bottomTextField.constant = 0;
        self.view.setNeedsUpdateConstraints()
        
        UIView.animateWithDuration(0.25) { () -> Void in
            self.view.layoutIfNeeded()
        }
    }
    
    
}