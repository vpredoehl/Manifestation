//
//  ViewController.swift
//  Manifestation
//
//  Created by Vincent Predoehl on 4/30/17.
//  Copyright © 2017 Vincent Predoehl. All rights reserved.
//

import UIKit

let maxNumPositions = 3

extension Preference
{
    var hasUserPhotos: Bool
    {
        get {
            guard let userKeys = RolloverPresets.userPhotoKeys else { return false }
            return userKeys.count > 0
        }
    }
    var hasChiImage: Bool   {   get     {   return Preference.chiTransferImage != nil  }   }
    var canPlay: Bool   {   get     {   return hasChiImage && hasTransferSequence()   }   }
    
    func hasTransferSequence(currentPreset p: Int? = -1, defaultPref dp: Preference? = nil) -> Bool {
        guard p != nil && p == -1 || dp != nil else {
            return false
        }
        let prefToTest = dp ?? self
        
        for i in prefToTest.imageIndex {
            if i != nil    {   return true }
        }
        return false
    }
    func canHiliteTrash(currentPreset p: Int?, defaultPref dp: Preference? = nil) -> Bool {
        return hasChiImage || hasTransferSequence(currentPreset: p, defaultPref: dp) || hasUserPhotos
    }
}

// MARK: -
class RolloverViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate,
    UITableViewDataSource, UITableViewDelegate
{
    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var trashItem: UIBarButtonItem!
    @IBOutlet weak var tb: UIToolbar!
    @IBOutlet weak var presetView: UITableView!
    
    @IBOutlet var constraintsForFullChiView: [NSLayoutConstraint]!
    @IBOutlet var constraintsForReducedChiView: [NSLayoutConstraint]!
    
    let animationDuration = 0.5
    let animLG = UILayoutGuide()

    var preset = RolloverPresets(fileURL: Preference.CloudDir.appendingPathComponent(presetsFile))
    var pref: Preference! 
    var isAnimating = false {   didSet  {   animationVC.isAnimating = isAnimating   }   }
    var animationVC: AnimationViewController!
    var rolloverTimer: Timer?
    var curAnim: UIViewPropertyAnimator?
    
    var chiImageView: UIImageView   {   get {   return animationVC.chiIV }   }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        if let chiW = RolloverPresets.imagePackage.fileWrappers?[chiImageFile],
            chiW.isRegularFile {
            Preference.chiTransferImage = chiW.regularFileContents
        }

        preset.addObserver(self, forKeyPath: "names", options: NSKeyValueObservingOptions.new, context: nil)
        preset.addObserver(self, forKeyPath: "defaultPref", options: NSKeyValueObservingOptions.new, context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RolloverViewController.docStateChanged(_:)), name: .UIDocumentStateChanged, object: nil)
    }
    
    deinit {
        removeObserver(self, forKeyPath: "names")
        removeObserver(self, forKeyPath: "defaultPref")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        preset.open { (s) in
            if s {
                self.presetView.isHidden = false
                self.editPresetBtn.isHidden = false
                self.addCurrentPresetBtn.isHidden = false
                self.tb.items![2].isEnabled = self.pref.canPlay
                self.tb.items![4].isEnabled = self.pref.canHiliteTrash(currentPreset: self.selectedPreset, defaultPref: self.preset.defaultPref)
                self.addCurrentPresetBtn.isEnabled = self.pref.hasTransferSequence(currentPreset: self.selectedPreset, defaultPref: self.preset.defaultPref)
            }
        }
    }

    override func viewDidLoad() {
        animationVC.pref = pref
        if let d = Preference.chiTransferImage {
            chiImageView.image = UIImage(data: d)
        }
        presetView.layer.borderWidth = 2.0
        presetView.layer.borderColor = UIColor.lightGray.cgColor
        editPresetBtn.isEnabled = preset.names.count > 0
        
        view.addLayoutGuide(animLG)
        // constraints for layout guide
        let margins = UIEdgeInsetsMake(8, 8, 8, 8)
        let safeLG = view.safeAreaLayoutGuide
        let topG = animLG.topAnchor.constraint(equalTo: safeLG.topAnchor, constant: 0)
        let bottomG = animLG.bottomAnchor.constraint(equalTo: tb.topAnchor, constant: 0)
        let leftG = animLG.leftAnchor.constraint(equalTo: safeLG.leftAnchor, constant: margins.left)
        let rightG = animLG.rightAnchor.constraint(equalTo: safeLG.rightAnchor, constant: -margins.right)
        NSLayoutConstraint.activate([topG, bottomG, leftG, rightG])
        
        let width = animationView.widthAnchor.constraint(equalTo: animLG.widthAnchor, constant: -(margins.left + margins.right))
        let height = animationView.heightAnchor.constraint(equalTo: animLG.heightAnchor, constant: -(margins.top + margins.bottom))
        constraintsForFullChiView.append(contentsOf: [width, height])
    }
    
    // MARK: - Tool Bar
    @IBAction func clearCloud(_ sender: Any) {
        let fm = FileManager.default

        func doDelete(contents c: [URL]) {
            c.forEach({ (f) in
                try? fm.removeItem(at: f)
            })
        }
        if let u = RolloverPresets.ubiq,
            let dirFiles = try? fm.contentsOfDirectory(at: u, includingPropertiesForKeys: nil) {
            doDelete(contents: dirFiles)
        }
        if let asF = try? fm.contentsOfDirectory(at: Preference.AppSupportDir, includingPropertiesForKeys: [], options: .skipsHiddenFiles) {
            doDelete(contents: asF)
        }
        if let asF = try? fm.contentsOfDirectory(at: Preference.DocDir, includingPropertiesForKeys: [], options: .skipsHiddenFiles) {
            doDelete(contents: asF)
        }
    }
    @IBAction func trash(_ sender: Any) {
        let ac = UIAlertController()
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let deleteChi = UIAlertAction(title: "Delete Transfer Image", style: .destructive)
        {
            (_) in
            Preference.chiTransferImage = nil
            self.chiImageView.image = #imageLiteral(resourceName: "Transfer/Chi Transfer")
            if let chiW = RolloverPresets.imagePackage.fileWrappers?[chiImageFile] {
                RolloverPresets.imagePackage.removeFileWrapper(chiW)
            }

            self.tb.items![2].isEnabled = self.pref.canPlay
            self.tb.items![4].isEnabled = self.pref.canHiliteTrash(currentPreset: self.selectedPreset, defaultPref: self.preset.defaultPref)
        }
        let deleteRollover = UIAlertAction(title: "Delete Rollover Images", style: .destructive)
        {
            (_) in
            let f = Preference.CloudDir.appendingPathComponent(defaultPositionsFile)
            
            self.preset.cleanImageCache(prefBeingDeleted: self.pref)
            self.pref.removeAll()
            self.preset.defaultPref = self.pref
            
            self.tb.items![2].isEnabled = self.pref.canPlay
            self.tb.items![4].isEnabled = self.pref.canHiliteTrash(currentPreset: self.selectedPreset, defaultPref: self.preset.defaultPref)
            self.addCurrentPresetBtn.isEnabled = false
        }
        let deleteUserPhotos = UIAlertAction(title: "Delete Photos" , style: .destructive)
        {
            (_) in
            if let files = try? FileManager.default.contentsOfDirectory(atPath: Preference.CloudDir.path) {
                let userPhotos = files.filter {   $0.hasPrefix("UI-") }
                let _ = userPhotos.map
                {
                    let f = Preference.CloudDir.appendingPathComponent($0)
                    try? FileManager.default.removeItem(at: f)
                }
                RolloverPresets.userPhotoKeys = [ ]
                self.pref.imageIndex = self.pref.imageIndex.map
                    {
                        (idx) in
                        guard let idx = idx else {   return nil }
                        return idx < 0 ? nil : idx
                }
            }
        }
        
        if let vc = ac.popoverPresentationController {
            vc.barButtonItem = trashItem
        }
        
        ac.addAction(cancel)
        if pref.hasChiImage {
            ac.addAction(deleteChi)
        }
        if pref.hasTransferSequence(currentPreset: selectedPreset, defaultPref: selectedPreset == nil ? preset.defaultPref : nil) {
            ac.addAction(deleteRollover)
        }
        if pref.hasUserPhotos {
            ac.addAction(deleteUserPhotos)
        }
        present(ac, animated: true)
    }
    @IBAction func playRollover(_ playBtn: UIBarButtonItem) {
        let willBeAnimating = !isAnimating
        let pt1 = CGPoint(x: 0.1, y: 1.0)
        let pt2 = CGPoint(x: 0.5, y: 1.0)
        let playOrPauseAnimation = UIViewPropertyAnimator(duration: willBeAnimating ? 2 : 5, controlPoint1: pt1, controlPoint2: pt2) {
            if willBeAnimating {
                NSLayoutConstraint.deactivate(self.constraintsForReducedChiView)
                NSLayoutConstraint.activate(self.constraintsForFullChiView)
                NSLayoutConstraint.deactivate(self.animationVC.constraintsForPauseAnimation)
                self.chiImageView.alpha = 0.2
            } else {
                NSLayoutConstraint.deactivate(self.constraintsForFullChiView)
                NSLayoutConstraint.activate(self.constraintsForReducedChiView)
                NSLayoutConstraint.activate(self.animationVC.constraintsForPauseAnimation)
                self.chiImageView.alpha = 1
            }
            self.addCurrentPresetBtn.isHidden = willBeAnimating
            self.editPresetBtn.isHidden = willBeAnimating
            self.view.layoutIfNeeded()
        }
        if willBeAnimating {
            playOrPauseAnimation.addCompletion {
                _ in
                DispatchQueue.main.async {
                    Preference.curRolloverPosition = 0
                    self.animationVC.pref = self.pref
                    self.rolloverTimer = Timer.scheduledTimer(timeInterval: 3, target: self.animationVC, selector: #selector(AnimationViewController.animate(t:)), userInfo: self.pref, repeats: true)
                    self.rolloverTimer?.fire()
                }
            }
        }
        else {
            rolloverTimer?.invalidate()
            rolloverTimer = nil
        }
        
        if !willBeAnimating {
            UIView.transition(with: self.animationVC.targetTextLabel, duration: self.animationDuration,
                              options: willBeAnimating ? UIViewAnimationOptions.transitionFlipFromLeft :  UIViewAnimationOptions.transitionFlipFromRight,
                              animations: { self.animationVC.targetTextStack.isHidden = !willBeAnimating },
                              completion: nil)
            UIView.transition(with: self.animationVC.trendTextLabel, duration: self.animationDuration,
                              options: willBeAnimating ? UIViewAnimationOptions.transitionFlipFromLeft :  UIViewAnimationOptions.transitionFlipFromRight,
                              animations: { self.animationVC.trendTextStack.isHidden = !willBeAnimating },
                              completion: nil)
            playOrPauseAnimation.addCompletion {
                _ in
                DispatchQueue.main.async {
                    UIView.transition(with: self.animationVC.targetTextLabel, duration: self.animationDuration,
                                      options: willBeAnimating ? UIViewAnimationOptions.transitionFlipFromLeft :  UIViewAnimationOptions.transitionFlipFromRight,
                                      animations: { self.animationVC.targetTextStack.isHidden = !willBeAnimating },
                                      completion: nil)
                    UIView.transition(with: self.animationVC.trendTextLabel, duration: self.animationDuration,
                                      options: willBeAnimating ? UIViewAnimationOptions.transitionFlipFromLeft :  UIViewAnimationOptions.transitionFlipFromRight,
                                      animations: { self.animationVC.trendTextStack.isHidden = !willBeAnimating },
                                      completion: nil)
                    UIView.transition(with: self.animationVC.rolloverIV,
                                      duration: willBeAnimating ? 0 : self.animationDuration / 0.75,  // make transition without animations if willBeAnimating
                        options: UIViewAnimationOptions.transitionFlipFromRight,
                        animations: {  self.animationVC.rolloverIV.image = nil  })
                }
            }
        }

        UIView.transition(with: self.animationVC.rolloverIV,
                          duration: willBeAnimating ? 0 : animationDuration * 0.75,  // make transition without animations if willBeAnimating
            options: willBeAnimating ? UIViewAnimationOptions.transitionFlipFromRight : UIViewAnimationOptions.curveLinear,
            animations: { if willBeAnimating { self.animationVC.rolloverIV.image = nil }  },
            completion:
            {
                _ in
                DispatchQueue.main.async {
                    if willBeAnimating { self.animationVC.rolloverStack.isHidden = !willBeAnimating }
                }
        })
        curAnim?.stopAnimation(true)
        curAnim = playOrPauseAnimation
        playOrPauseAnimation.startAnimation()
        
        tb.items![0].isEnabled = !willBeAnimating
        tb.items![4].isEnabled = !willBeAnimating
        tb.items![2] = UIBarButtonItem(barButtonSystemItem: willBeAnimating ? UIBarButtonSystemItem.pause : UIBarButtonSystemItem.play, target: self, action: #selector(RolloverViewController.playRollover(_:)))
        isAnimating = !isAnimating
    }
    
    @IBAction func takePicture(_ sender: UIBarButtonItem) {
        let imagePicker = UIImagePickerController()
        
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let img = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        chiImageView.image = img
        Preference.chiTransferImage = UIImagePNGRepresentation(img)
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case  "PositionSegue":
            let dest = segue.destination as! PositionTableViewController
            
            dest.pref = pref.copy() as! Preference
            dest.chiTransferImage = Preference.chiTransferImage
        case "AnimationSegue":
            animationVC = segue.destination as! AnimationViewController
        default: break
        }
    }
    
    // MARK: - Preset Table View -
    var selectedPreset: Int? = nil {
        didSet {
            if let s = oldValue {
                let ip = IndexPath(row: s, section: 0)
                let cell = presetView.cellForRow(at: ip) as? PresetTableViewCell
                
                cell?.presetButton.isSelected = false
                cell?.setSelected(false, animated: false)
            }
            else {
                // enable add current preset button if has default positions
                addCurrentPresetBtn.isEnabled = false
            }
            if let s = selectedPreset {
                let ip = IndexPath(row: s, section: 0)
                let cell = presetView.cellForRow(at: ip) as? PresetTableViewCell
                
                cell?.presetButton.isSelected = true
                cell?.setSelected(true, animated: false)
                pref = preset.presetPref[s]
            }
            else {
                pref = preset.defaultPref
                addCurrentPresetBtn.isEnabled = pref.hasTransferSequence(currentPreset: selectedPreset, defaultPref: pref)
            }
            preset.open { (s) in
                if s {
                    self.tb.items![2].isEnabled = self.pref.canPlay
                    self.tb.items![4].isEnabled = self.pref.canHiliteTrash(currentPreset: self.selectedPreset, defaultPref: self.preset.defaultPref)
                }
            }
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case "names"?:
            let names = change![NSKeyValueChangeKey.newKey] as! [String]
            editPresetBtn.isEnabled = names.count > 0
        case "defaultPref"?:
            if let def = preset.defaultPref {
                addCurrentPresetBtn.isEnabled = def.hasTransferSequence()
            }
            else {
                addCurrentPresetBtn.isEnabled = false
            }
        default:
            break
        }
    }
    
    @objc
    func docStateChanged(_ n: Notification) {
        switch preset.documentState {
        case .normal:
            let p = preset.defaultPref

            pref = p ?? Preference()
            presetView.reloadData()
            print("documentState: normal")
        case .closed:
            print("documentState: closed")
        case .inConflict:
            print("documentState: inConflict")
        case .savingError:
            print("documentState: savingError")
        case .editingDisabled:
            print("documentState: editingDisabled")
        case .progressAvailable:
            print("documentState: progressAvailable")
        default:
            break
        }
    }
    
    @IBOutlet weak var editPresetBtn: UIButton!
    @IBOutlet weak var addCurrentPresetBtn: UIButton!
    
    @IBAction func addPreset(_ sender: UIButton) {
        let a = UIAlertController(title: "Add New Preset", message: "What is the name of the new preset?", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let ok = UIAlertAction(title: "Ok", style: .default) { (_) in
            let n = a.textFields![0].text!
            let ip = IndexPath(row: self.preset.names.count, section: 0)
            let defaultPrefURL = Preference.CloudDir.appendingPathComponent(defaultPositionsFile)
            let newPresetF = Preference.CloudDir.appendingPathComponent(n + positionFileSuffix)
            var replacePreset = false
            
            
            let existingNameIdx = self.preset.names.index(of: n)
            if existingNameIdx != nil {
                let al = UIAlertController(title: "Duplicate Name", message: "A preset with that name already exists.  Would you like to replace it?", preferredStyle: .alert)
                let no = UIAlertAction(title: "No", style: .default) {
                    (_) in
                    return
                }
                let yes = UIAlertAction(title: "Yes", style: .destructive, handler: { (_) in
                    try? FileManager.default.removeItem(at: defaultPrefURL.appendingPathComponent(defaultPositionsFile))
                    replacePreset = true
                    moveFiles()
                })
                
                al.addAction(yes)
                al.addAction(no)
                self.present(al, animated: true)
            }
            
            func moveFiles() {
                if replacePreset {
                    self.preset.presetPref[existingNameIdx!] = self.preset.defaultPref!
                    self.selectedPreset = existingNameIdx
                }
                else {
                    self.preset.names.append(n)
                    self.preset.presetPref.append(self.preset.defaultPref!)
                    self.presetView.insertRows(at: [ip], with: .bottom)
                    self.selectedPreset = ip.row
                }
                self.preset.defaultPref = Preference()
            }
            
            guard existingNameIdx == nil else {
                return
            }
            moveFiles()
        }
        
        a.addTextField { (tf) in
            tf.keyboardType = .alphabet
            tf.addTarget(self, action: #selector(RolloverViewController.textChanged(_:)), for: .editingChanged)
        }
        
        a.addAction(cancel)
        a.addAction(ok)
        a.actions[1].isEnabled = false
        present(a, animated: true)
    }
    
    @IBAction func editPresets(_ sender: UIButton) {
        presetView.setEditing(!presetView.isEditing, animated: true)
        editPresetBtn.setTitle(presetView.isEditing ? "Done" : "Edit", for: .normal)
    }
    @IBAction func switchPreset(_ sender: UIButton) {
        let selectedIP = IndexPath(row: sender.tag, section: 0)

        // unselect previous cell
        if let s = selectedPreset {
            let ip = IndexPath(row: s, section: 0)
            
            presetView.deselectRow(at: ip, animated: false)
            guard s != sender.tag else {
                // tapped selected preset
                pref = preset.defaultPref
                selectedPreset = nil
                return
            }
        }
        presetView.selectRow(at: selectedIP, animated: false, scrollPosition: .none)
        selectedPreset = sender.tag
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            let row = indexPath.row
            let dirName = preset.names[row]
            let cellToDelete = presetView.cellForRow(at: indexPath) as! PresetTableViewCell

            try? FileManager.default.removeItem(at: Preference.CloudDir.appendingPathComponent(dirName))
            preset.cleanImageCache(prefBeingDeleted: preset.presetPref[row])
            preset.names.remove(at: row)
            preset.presetPref.remove(at: row)
            presetView.deleteRows(at: [indexPath], with: .fade)
            if cellToDelete.presetButton.isSelected {
                pref = preset.defaultPref
                selectedPreset = nil
            }

            let rowCount = presetView.numberOfRows(inSection: 0)
            for i in 0..<rowCount {
                let cell = presetView.cellForRow(at: IndexPath(row: i, section: 0)) as? PresetTableViewCell
                cell?.presetButton.tag = i
            }
            if preset.names.count == 0 {
                presetView.setEditing(false, animated: false)
                editPresetBtn.setTitle("Edit", for: .normal)
            }
        case .insert, .none:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! PresetTableViewCell
        switchPreset(cell.presetButton)
    }
    
    @objc
    func textChanged(_ tf: UITextField) {
        var resp: UIResponder! = tf
        while !(resp is UIAlertController) {
            resp = resp.next
        }
        (resp as! UIAlertController).actions[1].isEnabled = tf.text != ""
    }
    
    // MARK: - Table View Data Source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return preset.names.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SavedSetup", for: indexPath) as! PresetTableViewCell
        let render = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 5))
        let hiliteImage = render.image { (rctx) in
            let ctx = rctx.cgContext
            
            ctx.setFillColor(UIColor.green.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 5))
            }.resizableImage(withCapInsets: UIEdgeInsets.zero, resizingMode: .stretch)

        cell.presetButton.tag = indexPath.row
        if let s = selectedPreset  {
            let rowSelected = s == indexPath.row

            cell.presetButton.isSelected = rowSelected
            cell.isSelected = rowSelected
        }
        else {
            cell.presetButton.isSelected = false
            cell.isSelected = false
        }
        cell.presetButton.setTitle(preset.names[indexPath.row], for: .normal)
        cell.presetButton.setTitleColor(UIColor.brown, for: .selected)
        cell.presetButton.setBackgroundImage(hiliteImage, for: .selected)
        return cell
    }
}

// MARK: -
class PresetTableViewCell: UITableViewCell {
    @IBOutlet weak var presetButton: UIButton!
    
}

