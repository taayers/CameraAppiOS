//
//  WarrantyCellTableViewCell.swift
//  CameraApp
//
//  Created by Todd on 10/21/16.
//  Copyright © 2016 Triadic Software. All rights reserved.
//

import UIKit

class WarrantyCell: UITableViewCell {
    
    
    @IBOutlet weak var warrantyDaysLeft: UILabel!
    @IBOutlet weak var warrantyName: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
