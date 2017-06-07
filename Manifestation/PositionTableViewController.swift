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

class PositionTableViewController: UITableViewController, UITextViewDelegate {
    
    // MARK: Properties -
    enum SegmentType: Int {
        case trend
        case target
    }

    @IBOutlet weak var editItem: UIBarButtonItem!

    var imageIndex: [Int?]!
    var trendText: [String]!
    var targetText: [String]!
    var numPositions: Int!
    var selectedSegment = SegmentType.trend
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
        return section == TableSection.chiSection.rawValue ? 1 : numPositions
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
            let text = trendText[row]
            
            if let idx = imageIndex[row],
                let img = UIImage(named: "AoD/\(idx + 1)") {
                cell.cardButton.setImage(img, for: .normal)
            }
            cell.cardButton.tag = row
            
            if text == "" {
                cell.textView.textColor = UIColor.lightGray
                cell.textView.text = placeholderText
            } else {
                cell.textView.text = text
            }
            cell.textView.tag = indexPath.row
            cell.trendOrTarget.tag = indexPath.row
            return cell
        }
    }
    
    // MARK: - Table View Delegate -
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let row = indexPath.row
        
        if rowBeingEdited != nil && row != rowBeingEdited {
            let ipBeingEdited = IndexPath(row: rowBeingEdited!, section: TableSection.positionSection.rawValue)
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
        if editingStyle == .delete {
            let rowToDelete = indexPath.row
            
            imageIndex.remove(at: rowToDelete)
            trendText.remove(at: rowToDelete)
            targetText.remove(at: rowToDelete)
            numPositions = numPositions - 1
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if indexPath.section == TableSection.chiSection.rawValue {
            return .none
        }
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section != TableSection.chiSection.rawValue
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        let section = TableSection(rawValue: sourceIndexPath.section)!
        
        switch section {
        case .chiSection:
            return sourceIndexPath
        case .positionSection:
            return proposedDestinationIndexPath
        }
    }
    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        let fromRow = fromIndexPath.row
        let toRow = to.row
        let tempIdx = imageIndex[toRow]
        let tempTrendText = trendText[toRow]
        let tempTargetText = targetText[toRow]
        
        imageIndex[toRow] = imageIndex[fromRow]
        trendText[toRow] = trendText[fromRow]
        targetText[toRow] = targetText[fromRow]
        
        imageIndex[fromRow] = tempIdx
        trendText[fromRow] = tempTrendText
        targetText[fromRow] = tempTargetText
    }
    

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
        
        imageIndex[row!] = cardVC.imageIdx
        cell.cardButton.setImage(img, for: .normal)
    }
    

    // MARK: - Text View Delegage -
    func textViewDidBeginEditing(_ textView: UITextView) {
        let row = textView.tag
        let ip = IndexPath(row: row, section: TableSection.positionSection.rawValue)
        let cell = tableView.cellForRow(at: ip) as! PositionTableViewCell
        let selIdx = SegmentType(rawValue: cell.trendOrTarget.selectedSegmentIndex)!
        let text = selIdx == .trend ? trendText[row] : targetText[row]
        
        textView.text = text
        textView.textColor = UIColor.black
        rowBeingEdited = row
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
        let ip = IndexPath(row: idx, section: TableSection.positionSection.rawValue)
        let cell = tableView.cellForRow(at: ip) as! PositionTableViewCell
        
        selectedSegment = SegmentType(rawValue: sender.selectedSegmentIndex)!
        cell.textView.text = selectedSegment == .trend ? trendText[idx] : targetText[idx]
        cell.textView.becomeFirstResponder()
        print("Segmented Control: \(sender.tag) : \(sender.selectedSegmentIndex)")
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        let rolloverVC = navigationController?.viewControllers.first! as! RolloverViewController
        
        rolloverVC.trendText = trendText
        rolloverVC.targetText = targetText
        rolloverVC.rolloverImageIndex = imageIndex
        rolloverVC.numPositions = numPositions
        navigationController?.popViewController(animated: true)
    }
}
