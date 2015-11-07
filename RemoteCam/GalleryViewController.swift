//
//  GalleryViewController.swift
//  Actors
//
//  Created by Dario Lencina on 11/3/15.
//  Copyright © 2015 dario. All rights reserved.
//

import UIKit
import BFGallery

public class GalleryViewController : BFGalleryViewController {
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "Photos"
        self.view.backgroundColor = UIColor.blackColor()
        self.tableView.backgroundColor = UIColor.blackColor()
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) //hack
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override public func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if self.isBeingDismissed() || self.isMovingFromParentViewController() {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }
    
    override public func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}
