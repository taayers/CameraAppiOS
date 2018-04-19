//
//  ReceiptCell.swift
//  CameraApp
//
//  Created by Todd on 10/21/16.
//  Copyright © 2016 Triadic Software. All rights reserved.
//

import UIKit

class ReceiptCell: UITableViewCell {
    
    @IBOutlet weak var receiptDayMonth: UILabel!
    @IBOutlet weak var receiptYear: UILabel!
    @IBOutlet weak var receiptStore: UILabel!
    @IBOutlet weak var receiptTotal: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
