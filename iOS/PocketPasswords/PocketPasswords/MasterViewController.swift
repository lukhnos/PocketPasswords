//
//  MasterViewController.swift
//  PocketPasswords
//
//  Created by Lukhnos Liu on 3/24/15.
//  Copyright (c) 2015 Lukhnos Liu. All rights reserved.
//

import UIKit


class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil

    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("willResignActive"), name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("didBecomeActive"), name: UIApplicationDidBecomeActiveNotification, object: nil)
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = controllers[controllers.count-1].topViewController as? DetailViewController
        }
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = indexPath.row
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(PPStore.sharedInstance().count)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell

        cell.textLabel!.text = PPStore.sharedInstance().titleAtIndex(UInt(indexPath.row))
        return cell
    }

    func willResignActive() {
        PPStore.sharedInstance().clearStore()
        self.tableView.reloadData()
    }

    func didBecomeActive() {
        showUnlockAlert()
    }

    func showUnlockAlert() {
        var filePath = NSUserDefaults.standardUserDefaults().stringForKey("PasswordFile")
        if filePath == nil {
            simpleAlert("Error", message: "Please set the file in Settings")
            return
        }

        var fullFilePath : String! = nil
        if let docPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as? [String] {
            var docPath = docPaths[0]
            var contents = NSFileManager.defaultManager().contentsOfDirectoryAtPath(docPath, error: nil)
            fullFilePath = docPath.stringByAppendingPathComponent(filePath!)
        }

        if !NSFileManager.defaultManager().fileExistsAtPath(fullFilePath) {
            simpleAlert("Error", message: "Does not exist: \(fullFilePath)")
            return
        }

        var alert = UIAlertController(title: "Unlock App", message: "Enter the password to unlock", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.secureTextEntry = true
        }

        alert.addAction(UIAlertAction(title: "Unlock", style: .Default, handler: { (action) -> Void in
            if let textField = alert.textFields![0] as? UITextField {

                if count(textField.text) > 0 {
                    var store : PPStore = PPStore.sharedInstance()
                    store.loadStore(fullFilePath, passphrase: textField.text)
                    self.tableView.reloadData()
                } else {
                    self.showRetryAlert()
                }
            }
        }))

        presentViewController(alert, animated: true, completion: nil)
    }

    func showRetryAlert() {
        var alert = UIAlertController(title: "Invalid password", message: "Please try again", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Retry", style: .Default, handler: { (action) -> Void in
            self.showUnlockAlert()
        }))

        presentViewController(alert, animated: true, completion: nil)
    }

    func simpleAlert(title: String, message: String) {
        var alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
}

