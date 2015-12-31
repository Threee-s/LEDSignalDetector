//
//  RecordDetailCell.swift
//  LEDSignalDetector
//
//  Created by 文 光石 on 2015/02/23.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

import UIKit

class RecordDetailCell: UICollectionViewCell {
    
    @IBOutlet weak var recordDetailImageView: UIImageView!
    
    // todo:computed property in which change image of UIImageView
    var orgImage: UIImage?
    var detectedImage: UIImage?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
