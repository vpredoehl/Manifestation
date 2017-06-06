//
//  PositionTableViewCell.swift
//  Manifestation
//
//  Created by Vincent Predoehl on 6/4/17.
//  Copyright © 2017 Vincent Predoehl. All rights reserved.
//

import UIKit

class PositionTableViewCell: UITableViewCell {
    
    // MARK: Properties -
    @IBOutlet weak var cardButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var trendOrTarget: UISegmentedControl!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
