//
//  PositionTableViewController.swift
//  Manifestation
//
//  Created by Vincent Predoehl on 6/4/17.
//  Copyright © 2017 Vincent Predoehl. All rights reserved.
//

import UIKit

let numPositions = 3

class PositionTableViewController: UITableViewController, UITextViewDelegate {
    
    // MARK: Properties -
    enum SegmentType: Int {
        case trend
        case target
    }

    @IBOutlet weak var targetOrTrend: UISegmentedControl!

    var imageIndex: [Int?]!
    var trendText: [String]!
    var targetText: [String]!
    var selectedSegment = SegmentType.trend

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numPositions
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "PositionTableViewCell", for: indexPath) as! PositionTableViewCell
        let img = UIImage(named: "AoD/\(row + 1)")
        let text = trendText[row]

        cell.cardImageView.image = img
        
        if text == "" {
            cell.textView.textColor = UIColor.lightGray
            cell.textView.text = "Place text here"
        } else {
            cell.textView.text = text
        }
        cell.textView.tag = indexPath.row
        cell.trendOrTarget.tag = indexPath.row
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("prepare for segue")
    }
    

    // MARK: - Text View Delegage -
    func textViewDidBeginEditing(_ textView: UITextView) {
        let row = textView.tag
        let ip = IndexPath(row: row, section: 0)
        let cell = tableView.cellForRow(at: ip) as! PositionTableViewCell
        let selIdx = SegmentType(rawValue: cell.trendOrTarget.selectedSegmentIndex)!
        let text = selIdx == .trend ? trendText[row] : targetText[row]
        
        textView.text = text
        textView.textColor = UIColor.black
    }
    
    func textViewDidChange(_ textView: UITextView) {
        print("TextView: \(textView.text)")
        let idx = textView.tag
        
        if selectedSegment == .trend {
            trendText[idx] = textView.text
        } else {
            targetText[idx] = textView.text
        }
    }
    
    // MARK: - Segmented Control -
    @IBAction func selectTrendOrTarget(_ sender: UISegmentedControl) {
        let idx = sender.tag
        let ip = IndexPath(row: idx, section: 0)
        let cell = tableView.cellForRow(at: ip) as! PositionTableViewCell
        
        selectedSegment = SegmentType(rawValue: sender.selectedSegmentIndex)!
        cell.textView.text = selectedSegment == .trend ? trendText[idx] : targetText[idx]
//        tableView.reloadRows(at: [ip], with: .automatic)
        print("Segmented Control: \(sender.tag) : \(sender.selectedSegmentIndex)")
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        let rolloverVC = navigationController?.viewControllers.first! as! RolloverViewController
        
        rolloverVC.trendText = trendText
        rolloverVC.targetText = targetText
        rolloverVC.rolloverImageIndex = imageIndex
        navigationController?.popViewController(animated: true)
    }
}
