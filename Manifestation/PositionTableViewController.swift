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

extension Preference
{
    var canInsertRow: Bool {
        get {
            return imageIndex.filter { $0 == nil   }.count == 0 // check for nil rows
        }
    }
}

class PositionTableViewController: UIViewController, UITextViewDelegate,
    UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Properties -
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var chiImageAdapted: UIButton!
    
    var pref: Preference!
    var rowBeingEdited: Int?
    var adaptedPositionSection: TableSection {
        get {
            return traitCollection.horizontalSizeClass == .regular
                ? TableSection(rawValue: 0)!
                : .positionSection
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItems?[1] = editButtonItem
        NotificationCenter.default.addObserver(self, selector: #selector(PositionTableViewController.keyboardAppearing(_:)), name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PositionTableViewController.keyboardDisappearing(_:)), name: .UIKeyboardWillHide, object: nil)
        
        if let d = pref.chiTransferImage,
            let img = UIImage(data: d) {
            chiImageAdapted.setImage(img, for: .normal)
        }

    }
    
    // MARK: - Keyboard Notifications -
    
    var oldContentInset = UIEdgeInsets.zero
    var oldIndicatorInset = UIEdgeInsets.zero
    var oldContent = CGPoint.zero
    var keyboardShowing = false
    
    @objc
    func keyboardAppearing(_ n: Notification) {
        if keyboardShowing {
            return
        }
        let d = n.userInfo!
        var r = d[UIKeyboardFrameEndUserInfoKey] as! CGRect
        r = tableView.convert(r, to: nil)

        keyboardShowing = true
        oldContentInset = tableView.contentInset
        oldIndicatorInset = tableView.scrollIndicatorInsets
        oldContent = tableView.contentOffset
        
        
        tableView.contentInset.bottom = r.size.height
        tableView.scrollIndicatorInsets.bottom = r.size.height
        r = tableView.rectForRow(at: IndexPath(row: rowBeingEdited!, section: adaptedPositionSection.rawValue))
        tableView.scrollRectToVisible(r, animated: true)
    }
    
    @objc
    func keyboardDisappearing(_ n: Notification) {
        if !keyboardShowing {
            return
        }
        keyboardShowing = false
        tableView.contentInset = oldContentInset
        tableView.scrollIndicatorInsets = oldIndicatorInset
        tableView.contentOffset = oldContent
        tableView.setNeedsDisplay()
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return traitCollection.horizontalSizeClass == .compact ? 2 : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if traitCollection.horizontalSizeClass == .regular {
            return pref.numPositions
        }
        return section == TableSection.chiSection.rawValue ? 1 : pref.numPositions
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let section = traitCollection.horizontalSizeClass == .regular
            ? TableSection.positionSection
            : TableSection(rawValue: indexPath.section)!

        switch section {
        case .chiSection:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChiCell", for: indexPath) as! ChiCellTableViewCell
            
            if pref.chiTransferImage != nil {
                let img = UIImage(data: pref.chiTransferImage!)
                cell.chiButton.setImage(img, for: .normal)
            }
            return cell
        case .positionSection:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PositionTableViewCell", for: indexPath) as! PositionTableViewCell
            
            if let idx = pref.rolloverIndex(forRow: row),
                let img = idx < 0
                    ? pref.image(forKey: idx)
                    : UIImage(named: "AoD/\(idx + 1)") {
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
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        tableView.setEditing(editing, animated: true)
        if editing,
            let row = rowBeingEdited {
            let cell = tableView.cellForRow(at: IndexPath(row: row, section: adaptedPositionSection.rawValue)) as! PositionTableViewCell
            
            cell.textView.resignFirstResponder()
        }
    }
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        if traitCollection.horizontalSizeClass == .regular {
            return true
        }
        return indexPath.section != TableSection.chiSection.rawValue
    }
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if let row = rowBeingEdited {
            let ipBeingEdited = IndexPath(row: row, section: adaptedPositionSection.rawValue)
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
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let numRows = tableView.numberOfRows(inSection: adaptedPositionSection.rawValue)

        if editingStyle == .delete {
            let rowToDelete = indexPath.row
            let fromIdx = traitCollection.horizontalSizeClass == .compact
                ? rowToDelete+1
                : rowToDelete

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
            tableView.scrollToRow(at: ip, at: .none, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if traitCollection.horizontalSizeClass == .compact && indexPath.section == TableSection.chiSection.rawValue {
            return .none
        }
        let rowCount = tableView.numberOfRows(inSection: adaptedPositionSection.rawValue)
        
        return indexPath.row == rowCount-1 && rowCount < maxNumPositions
            && pref.canInsertRow
            || rowCount == 1
            ? .insert : .delete
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if pref.numPositions == 1 {
            return false
        }
        return indexPath.section != TableSection.chiSection.rawValue
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        let toSection = TableSection(rawValue: proposedDestinationIndexPath.section)!
        
        if traitCollection.horizontalSizeClass == .regular {
            return proposedDestinationIndexPath
        }
        if toSection == .chiSection {
            return IndexPath(row: 0, section: TableSection.positionSection.rawValue)
        }
        return proposedDestinationIndexPath
    }
    
    // Override to support rearranging the table view.
    func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
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
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if traitCollection.horizontalSizeClass == .regular {
            return "Positions"
        }

        switch section {
        case 0:
            return "Transfer Image"
        default:
            return "Positions"
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let v = view as! UITableViewHeaderFooterView
        
        v.textLabel?.textAlignment = .center
    }
    
    private
    func updateTags(forRow idx: Int, to: Int)
    {
        let cellToUpdate = tableView.cellForRow(at: IndexPath(row: idx, section: adaptedPositionSection.rawValue)) as! PositionTableViewCell
        
        cellToUpdate.cardButton.tag = to
        cellToUpdate.textView.tag = to
        cellToUpdate.trendOrTarget.tag = to
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let cardVC = segue.destination as! CardsViewController
        let cardButton = sender as! UIButton
        
        cardVC.pref = pref
        cardVC.row = cardButton.tag
        if let row = rowBeingEdited {
            let ip = IndexPath(row: row, section: adaptedPositionSection.rawValue)
            let cell = tableView.cellForRow(at: ip) as! PositionTableViewCell
            
            cell.textView.resignFirstResponder()
        }
    }
    
    @IBAction func chiLongPress(_ sender: UILongPressGestureRecognizer) {
        let iVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ShowImage") as! ImageVC
        
        if let img = pref.chiTransferImage {
            iVC.loadViewIfNeeded()
            iVC.imageView.image = UIImage(data: img)
            iVC.modalPresentationStyle = .overFullScreen
            iVC.modalTransitionStyle = .coverVertical
            present(iVC, animated: true)
        }
    }
    
    @IBAction
    func ImageSelectedUnwind(_ segue: UIStoryboardSegue, sender: CardCollectionViewCell) {
        let cardVC = segue.source as! CardsViewController
        let row = cardVC.row
        let ip = IndexPath(row: cardVC.row, section: adaptedPositionSection.rawValue)
        let cell = tableView.cellForRow(at: ip) as! PositionTableViewCell
        let img = cardVC.userImage ?? (cardVC.returnImageIdx < 0
            ? pref.image(forKey: cardVC.returnImageIdx)
            : UIImage(named: "AoD/\(cardVC.returnImageIdx + 1)"))
        
        if let img = img {
            let imgKey = cardVC.returnImageIdx!
            pref.setImage(img, forKey: imgKey)
        }
        pref.set(imageIndex: cardVC.returnImageIdx, forRow: row!)
        cell.cardButton.setImage(img, for: .normal)
        if tableView.isEditing {    //
            tableView.isEditing = false
            tableView.isEditing = true
        }
    }
    
    // MARK: - Image Picker -
    @IBAction func chiTransferTapped(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let img = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        pref.chiTransferImage = UIImagePNGRepresentation(img)
        chiImageAdapted.setImage(img, for: .normal)
        if traitCollection.horizontalSizeClass != .regular {
            tableView.reloadData()
        }
        
        dismiss(animated: true)
    }

    // MARK: - Text View Delegage -
    func textViewDidBeginEditing(_ textView: UITextView) {
        let row = textView.tag
        let ip = IndexPath(row: row, section: adaptedPositionSection.rawValue)
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
        let ip = IndexPath(row: idx, section: adaptedPositionSection.rawValue)
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
        let fPosn = Preference.DocDir.appendingPathComponent(positionFile)
        let tempPhotosF = Preference.DocDir.appendingPathComponent(tempPhotoKeysFile)
        let rolloverVC = navigationController?.viewControllers.first! as! RolloverViewController

        if let img = pref.chiTransferImage {
            let f = Preference.DocDir.appendingPathComponent(chiImageFile)
            
            if rolloverVC.pref.chiTransferImage != pref.chiTransferImage
                && NSKeyedArchiver.archiveRootObject(img, toFile: f.path) {
                print("Image saved.")
            }
        }
        
        rolloverVC.pref = pref
        if NSKeyedArchiver.archiveRootObject(pref, toFile: fPosn.path) {
            print("Positions saved.")
            try? FileManager.default.removeItem(atPath: tempPhotosF.path)
        }
        
        if let d = pref.chiTransferImage {
            rolloverVC.chiImageView.image = UIImage(data: d)
        }
        navigationController?.popViewController(animated: true)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let h = traitCollection.horizontalSizeClass
        let v = traitCollection.verticalSizeClass
        
        print("h: \(h.rawValue)")
        print("v: \(v.rawValue)")
        
        tableView.reloadData()
    }
    
    // MARK: - View Controller Animated Transitioning -
    
}

class ImageVC: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ImgaeVC loaded")
    }
    
    @IBAction func tap(_ sender: UITapGestureRecognizer) {
        presentingViewController?.dismiss(animated: true)
    }
    
}
