//
//  PositionTableViewController.swift
//  Manifestation
//
//  Created by Vincent Predoehl on 6/4/17.
//  Copyright © 2017 Vincent Predoehl. All rights reserved.
//

import UIKit

let placeholderText = "Place text here"

enum TableSection: Int {
    case chiSection
    case positionSection
}

enum SegmentType: Int {
    case trend
    case target
}

class PositionTableViewController: UITableViewController, UITextViewDelegate {
    
    // MARK: Properties -
    @IBOutlet weak var editItem: UIBarButtonItem!

    var pref: Preference!
    var rowBeingEdited: Int?

    override func viewDidLoad() {
        super.viewDidLoad()

         navigationItem.rightBarButtonItems?[1] = editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == TableSection.chiSection.rawValue ? 1 : pref.numPositions
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let section = TableSection(rawValue: indexPath.section)!

        switch section {
        case .chiSection:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChiCell", for: indexPath)
            
            return cell
        case .positionSection:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PositionTableViewCell", for: indexPath) as! PositionTableViewCell
            
            if let idx = pref.rolloverIndex(forRow: row),
                let img = UIImage(named: "AoD/\(idx + 1)") {
                cell.cardButton.setImage(img, for: .normal)
            }
            else {
                cell.cardButton.setImage(nil, for: .normal)
            }
            cell.cardButton.tag = row
            cell.trendOrTarget.selectedSegmentIndex = pref.segment(forRow: row).rawValue
            
            let text = pref.userText(forRow: row, ofType: pref.segment(forRow: row))
            if text == "" {
                cell.textView.textColor = UIColor.lightGray
                cell.textView.text = placeholderText
            } else {
                cell.textView.textColor = UIColor.black
                cell.textView.text = text
            }
            cell.textView.tag = indexPath.row
            cell.trendOrTarget.tag = indexPath.row
            return cell
        }
    }
    
    // MARK: - Table View Delegate -
//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return indexPath.section == TableSection.chiSection.rawValue ? 200 : 140
//    }
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing,
            let row = rowBeingEdited {
            let cell = tableView.cellForRow(at: IndexPath(row: row, section: TableSection.positionSection.rawValue)) as! PositionTableViewCell
            
            cell.textView.resignFirstResponder()
        }
    }
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section != TableSection.chiSection.rawValue
    }
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if let row = rowBeingEdited {
            let ipBeingEdited = IndexPath(row: row, section: TableSection.positionSection.rawValue)
            let cell = tableView.cellForRow(at: ipBeingEdited) as! PositionTableViewCell
            cell.textView.resignFirstResponder()
        }
        return false
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let numRows = tableView.numberOfRows(inSection: TableSection.positionSection.rawValue)

        if editingStyle == .delete {
            let rowToDelete = indexPath.row
            let fromIdx = rowToDelete+1

            for idx in fromIdx ..< numRows {
                updateTags(forRow: idx, to: idx-1)
            }
            pref.remove(at: rowToDelete)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            var ip = indexPath
            let fromIdx = ip.row+1
            
            for idx in fromIdx ..< numRows {
                updateTags(forRow: idx, to: idx+1)
            }
            pref.add()
            ip.row = pref.numPositions - 1
            tableView.insertRows(at: [ip], with: .automatic)
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if indexPath.section == TableSection.chiSection.rawValue {
            return .none
        }
        let rowCount = tableView.numberOfRows(inSection: indexPath.section)
        
        return indexPath.row == rowCount-1 && rowCount < maxNumPositions  ? .insert : .delete
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if pref.numPositions == 1 {
            return false
        }
        return indexPath.section != TableSection.chiSection.rawValue
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        let toSection = TableSection(rawValue: proposedDestinationIndexPath.section)!
        
        if toSection == .chiSection {
            return IndexPath(row: 0, section: TableSection.positionSection.rawValue)
        }
        return proposedDestinationIndexPath
    }
    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        let toIdx = to.row
        let fromIdx = fromIndexPath.row
        
        guard fromIdx != toIdx else {
            return
        }
        
        if fromIdx > toIdx {
            for idx in toIdx+1 ... fromIdx {
                updateTags(forRow: idx, to: idx+1)
            }
        } else {
            for idx in fromIdx+1 ... toIdx {
                updateTags(forRow: idx, to: idx-1)
            }
        }
        updateTags(forRow: fromIdx, to: toIdx)
        
        pref.move(fromRow: fromIndexPath.row, to: to.row)
        tableView.reloadData()
    }
    
    private
    func updateTags(forRow idx: Int, to: Int)
    {
        let cellToUpdate = tableView.cellForRow(at: IndexPath(row: idx, section: TableSection.positionSection.rawValue)) as! PositionTableViewCell
        
        cellToUpdate.cardButton.tag = to
        cellToUpdate.textView.tag = to
        cellToUpdate.trendOrTarget.tag = to
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let cardVC = segue.destination as! CardsViewController
        let cardButton = sender as! UIButton
        
        cardVC.row = cardButton.tag
        if let row = rowBeingEdited {
            let ip = IndexPath(row: row, section: TableSection.positionSection.rawValue)
            let cell = tableView.cellForRow(at: ip) as! PositionTableViewCell
            
            cell.textView.resignFirstResponder()
        }
    }
    
    @IBAction
    func ImageSelectedUnwind(_ segue: UIStoryboardSegue, sender: CardCollectionViewCell) {
        let cardVC = segue.source as! CardsViewController
        let row = cardVC.row
        let ip = IndexPath(row: cardVC.row, section: TableSection.positionSection.rawValue)
        let cell = tableView.cellForRow(at: ip) as! PositionTableViewCell
        let img = UIImage(named: "AoD/\(cardVC.imageIdx + 1)")
        
        pref.set(imageIndex: cardVC.imageIdx, forRow: row!)
        cell.cardButton.setImage(img, for: .normal)
    }
    

    // MARK: - Text View Delegage -
    func textViewDidBeginEditing(_ textView: UITextView) {
        let row = textView.tag
        let ip = IndexPath(row: row, section: TableSection.positionSection.rawValue)
        let cell = tableView.cellForRow(at: ip) as! PositionTableViewCell
        let selIdx = SegmentType(rawValue: cell.trendOrTarget.selectedSegmentIndex)!
        let text = pref.userText(forRow: row, ofType: selIdx)

        textView.text = text
        textView.textColor = UIColor.black
        rowBeingEdited = row
        tableView.setEditing(false, animated: true)
        setEditing(false, animated: true)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            // restore placeholder text
            textView.textColor = UIColor.lightGray
            textView.text = placeholderText
        }
        rowBeingEdited = nil
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let idx = textView.tag
        
        pref.set(text: textView.text, forRow: idx, ofType: pref.segment(forRow: idx))
    }
    
    // MARK: - Segmented Control -
    @IBAction func selectTrendOrTarget(_ sender: UISegmentedControl) {
        let idx = sender.tag
        let ip = IndexPath(row: idx, section: TableSection.positionSection.rawValue)
        let cell = tableView.cellForRow(at: ip) as! PositionTableViewCell
        let selectedSegment = SegmentType(rawValue: sender.selectedSegmentIndex)!
        
        cell.textView.text = pref.userText(forRow: idx, ofType: selectedSegment)
        cell.textView.textColor = UIColor.black
        if rowBeingEdited != nil {
            cell.textView.becomeFirstResponder()
            rowBeingEdited = idx
        }
        else if cell.textView.text == "" {
            // restore placeholder text
            cell.textView.textColor = UIColor.lightGray
            cell.textView.text = placeholderText
        }
        pref.set(segment: selectedSegment, forRow: idx)
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        let dd = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
        let f = dd.appendingPathComponent("positions")
        let rolloverVC = navigationController?.viewControllers.first! as! RolloverViewController

        if NSKeyedArchiver.archiveRootObject(pref, toFile: f.path) {
            print("Positions saved.")
        }
        rolloverVC.pref = pref
        navigationController?.popViewController(animated: true)
    }
}
