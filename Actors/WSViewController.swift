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
    
    var url : Optional<NSURL> = Optional.None
    
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
    
    lazy var connected : Receive = {[unowned self](msg : Message) in
        switch(msg) {
            case let w as WebSocketMsg.SendMessage:
                ^{ () in
                    self.receivedMessages.append(("You: \(w.message)", NSDate.init()))
                    let i = self.receivedMessages.count - 1
                    let lastRow = NSIndexPath.init(forRow: i, inSection: 0)
                    self.ctrl?.tableView.insertRowsAtIndexPaths([lastRow], withRowAnimation: UITableViewRowAnimation.Automatic)
                    self.ctrl?.tableView.scrollToRowAtIndexPath(lastRow, atScrollPosition: UITableViewScrollPosition.Middle, animated: true)
                }
                self.wsClient ! WebSocketMsg.SendMessage(sender: self.this, message: w.message)
                break
                
            case let w as WebSocketMsg.OnMessage:
                ^{ () in
                    self.receivedMessages.append(("Server: \(w.message)", NSDate.init()))
                    let i = self.receivedMessages.count - 1
                    let lastRow = NSIndexPath.init(forRow: i, inSection: 0)
                    self.ctrl?.tableView.insertRowsAtIndexPaths([lastRow], withRowAnimation: UITableViewRowAnimation.Automatic)
                    self.ctrl?.tableView.scrollToRowAtIndexPath(lastRow, atScrollPosition: UITableViewScrollPosition.Middle, animated: true)
                }
                break
                
            case let w as WebSocketMsg.OnDisconnect:
                self.onDisconnect(w)
                break
                
            default:
                self.receive(msg)
        }
    }
    
    func onDisconnect(msg : WebSocketMsg.OnDisconnect) -> Void {
        ^{ [unowned self] () in
            self.ctrl?.title = "Disconnected"
            self.ctrl?.navigationItem.prompt = msg.error?.localizedDescription
            self.unbecome()
        }
        
        self.scheduleOnce(1,block: { () in
            if let url = self.url {
                self.this ! WebSocketMsg.Connect(url: url, delegate: self.this)
            }
        })
    }

    override public func receive(msg: Message) {
        switch(msg) {
            case let w as WebSocketMsg.Connect:
                wsClient ! WebSocketMsg.Connect(url: w.url, delegate: this)
                url = w.url
                ^{ () in
                    self.ctrl?.title = "Connecting"
                }
                break
                
            case is WebSocketMsg.OnConnect:
                ^{ () in
                    self.ctrl?.title = "Connected"
                    self.ctrl?.navigationItem.prompt = nil
                    self.ctrl?.textField.becomeFirstResponder()
                    self.become("connected", state:self.connected)
                }
                break
                
            case is Disconnect:
                wsClient ! Disconnect(sender: this)
                break
                
            case let w as SetWSController:
                ctrl = w.ctrl
                ^{ () in
                    self.ctrl?.tableView.dataSource = self
                    self.ctrl?.tableView.delegate = self
                }
                break
            case let d as WebSocketMsg.OnDisconnect:
                self.onDisconnect(d)
                
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
        wsCtrl ! WebSocketMsg.Connect(url: NSURL(string: "wss://echo.websocket.org")!, delegate: wsCtrl)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillAppear:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillDisappear:", name: UIKeyboardWillHideNotification, object: nil)
        send.addTarget(self, action: "onClick:", forControlEvents: .TouchUpInside)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        wsCtrl ! WebSocketMsg.SendMessage(sender: wsCtrl, message: textField.text!)
        return true
    }
    
    @objc func onClick(btn : UIButton) {
        wsCtrl ! WebSocketMsg.SendMessage(sender: wsCtrl, message: textField.text!)
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