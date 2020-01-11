//
//  AddAttachmentViewController.swift
//  NotePlus
//
//  Created by 张俊 on 2020/1/11.
//  Copyright © 2020 张俊. All rights reserved.
//

import Cocoa

class AddAttachmentViewController: NSViewController {
	
	var delegate: AddAttachmentDelegate?
	
	override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

	@IBAction func addFile(_ sender: Any) {
		delegate?.addFile()
	}
}

protocol AddAttachmentDelegate {
	func addFile()
}
