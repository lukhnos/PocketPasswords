//
//  DetailViewController.swift
//  PocketPasswords
//
//  Created by Lukhnos Liu on 3/24/15.
//  Copyright (c) 2015 Lukhnos Liu. All rights reserved.
//

import UIKit

class DetailViewController: UITableViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!


    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    var detailItem: Int = -1 {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        self.tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("willResignActive"), name: UIApplicationWillResignActiveNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func willResignActive() {
        detailItem = -1
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if detailItem >= 0 {
            return PPStore.sharedInstance().headerRow.count
        }
        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("DataCell", forIndexPath: indexPath) as! UITableViewCell

        let header = PPStore.sharedInstance().headerRow as! [String]
        let row = PPStore.sharedInstance().rowAtIndex(UInt(detailItem)) as! [String]

        var title = header[indexPath.row]
        var text = row[indexPath.row]

        if count(text) == 0 {
            text = "N/A"
        } else if title == "password" {
            text = "********"
        }

        cell.textLabel!.text = text
        cell.detailTextLabel!.text = title


        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let header = PPStore.sharedInstance().headerRow as! [String]
        let row = PPStore.sharedInstance().rowAtIndex(UInt(detailItem)) as! [String]
        var title = header[indexPath.row]
        var text = row[indexPath.row]

        if title != "password" {
            UIPasteboard.generalPasteboard().string = text
            simpleAlert("String copied", message: "For field: \(title)")
        } else {
            var alert = UIAlertController(title: "Password Field", message: "Choose Action", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Show", style: .Default, handler: { (action) -> Void in
                self.simpleAlert("Password", message: text)
            }))
            alert.addAction(UIAlertAction(title: "Copy", style: .Default, handler: { (action) -> Void in
                UIPasteboard.generalPasteboard().string = text
            }))
            presentViewController(alert, animated: true, completion: nil)
        }

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    func simpleAlert(title: String, message: String) {
        var alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
}

