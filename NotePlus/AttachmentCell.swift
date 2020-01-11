//
//  AttachmentCell.swift
//  NotePlus
//
//  Created by 张俊 on 2020/1/11.
//  Copyright © 2020 张俊. All rights reserved.
//

import Cocoa

class AttachmentCell: NSCollectionViewItem {
	
	weak var delegate: AttachmentCellDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
	override func mouseDown(with event: NSEvent) {
		if 2 == event.clickCount {
			delegate?.openSelectedAttachment(collectionViewItem: self)
		}
	}
}
