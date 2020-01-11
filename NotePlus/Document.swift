//
//  Document.swift
//  NotePlus
//
//  Created by 张俊 on 2020/1/6.
//  Copyright © 2020 张俊. All rights reserved.
//

import Cocoa
import MapKit

enum DocumentFileNames: String {
	case textFile = "Text.rtf"
	case attachmentsDirectory = "Attachments"
}

enum ErrorCode: Int {
	case CannotAccessDocument
	case CannotLoadFileWrappers
	case CannotLoadText
	case CannotAccessAttachments
	case CannotSaveText
	case CannotSaveAttachment
}

let ErrorDomain = "NotePlusErrorDomain"

func err(code: ErrorCode, _ userInfo: [NSObject : AnyObject]? = nil) -> NSError {
	return NSError(domain: ErrorDomain, code: code.rawValue, userInfo: (userInfo as! [String : Any]))
}

class Document: NSDocument {
	
	@IBOutlet weak var attachmentsList: NSCollectionView!
	
	@IBAction func addAttachment(_ sender: NSButton) {
//		let viewController = AddAttachmentViewController(nibName: "AddAttachmentViewController", bundle: Bundle.main)
//		viewController.delegate = self
//		popover = .init()
//		popover?.behavior = .transient
//		popover?.contentViewController = viewController
//		popover?.show(relativeTo: sender.bounds, of: sender, preferredEdge: NSRectEdge.maxX)
		addFile()
	}
	
	@objc var text: NSAttributedString = .init()
	var documentFileWrapper = FileWrapper(directoryWithFileWrappers: [:])
	var popover: NSPopover?
	
	dynamic var attachedFiles: [FileWrapper]? {
		if let attachmentsFileWrappers = attachmentsDirectoryWrapper?.fileWrappers {
			let attachments = Array(attachmentsFileWrappers.values)
			return attachments
		} else {
			return nil
		}
	}

	private var attachmentsDirectoryWrapper: FileWrapper? {
		guard let fileWrappers = documentFileWrapper.fileWrappers else {
			NSLog("Attemption to access document's content, but none found!")
			return nil
		}
		
		var attachmentsDirectoryWrapper = fileWrappers[DocumentFileNames.attachmentsDirectory.rawValue]
		
		if nil == attachmentsDirectoryWrapper {
			attachmentsDirectoryWrapper = FileWrapper(directoryWithFileWrappers: [:])
			attachmentsDirectoryWrapper?.preferredFilename = DocumentFileNames.attachmentsDirectory.rawValue
			documentFileWrapper.addFileWrapper(attachmentsDirectoryWrapper!)
		}
		
		return attachmentsDirectoryWrapper
	}
	
	func addAttachment(at url: URL) throws {
		guard attachmentsDirectoryWrapper != nil else {
			throw err(code: .CannotAccessAttachments)
		}
		self.willChangeValue(forKey: "attachedFiles")
		let netAttachment = try FileWrapper(url: url, options: .immediate)
		attachmentsDirectoryWrapper?.addFileWrapper(netAttachment)
		updateChangeCount(.changeDone)
		didChangeValue(forKey: "attachedFiles")
	}
	
	override init() {
	    super.init()
		// Add your subclass-specific initialization here.
	}

	override class var autosavesInPlace: Bool {
		return true
	}

	override var windowNibName: NSNib.Name? {
		// Returns the nib file name of the document
		// If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
		return NSNib.Name("Document")
	}

	override func data(ofType typeName: String) throws -> Data {
		// Insert code here to write your document to data of the specified type, throwing an error in case of failure.
		// Alternatively, you could remove this method and override fileWrapper(ofType:), write(to:ofType:), or write(to:ofType:for:originalContentsURL:) instead.
		throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
	}

	override func read(from data: Data, ofType typeName: String) throws {
		// Insert code here to read your document from the given data of the specified type, throwing an error in case of failure.
		// Alternatively, you could remove this method and override read(from:ofType:) instead.
		// If you do, you should also override isEntireFileLoaded to return false if the contents are lazily loaded.
		throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
	}

	override func fileWrapper(ofType typeName: String) throws -> FileWrapper {
		let textRTFData = try text.data(from: NSRange(0..<text.length), documentAttributes: [NSAttributedString.DocumentAttributeKey.documentType : NSAttributedString.DocumentType.rtf])
		
		if let oldTextFileWrapper = documentFileWrapper.fileWrappers?[DocumentFileNames.textFile.rawValue] {
			documentFileWrapper.removeFileWrapper(oldTextFileWrapper)
		}
		
		documentFileWrapper.addRegularFile(withContents: textRTFData, preferredFilename: DocumentFileNames.textFile.rawValue)
		
		return documentFileWrapper
	}
	
	override func read(from fileWrapper: FileWrapper, ofType typeName: String) throws {
		guard let fileWrappers = fileWrapper.fileWrappers else {
			throw err(code: .CannotLoadFileWrappers)
		}
		
		guard let documentTextData = fileWrappers[DocumentFileNames.textFile.rawValue]?.regularFileContents else {
			throw err(code: .CannotLoadText)
		}
		
		guard let documentText = NSAttributedString(rtf: documentTextData, documentAttributes: nil) else {
			throw err(code: .CannotLoadText)
		}
		
		documentFileWrapper = fileWrapper
		text = documentText
	}
}

extension Document: AddAttachmentDelegate {
	func addFile() {
		let panel = NSOpenPanel()
		panel.allowsMultipleSelection = false
		panel.canChooseDirectories = false
		panel.canChooseFiles = true
		
		panel.begin { (result) in
			if result == NSApplication.ModalResponse.OK, let resultURL = panel.url {
				do {
					try self.addAttachment(at: resultURL)
					self.attachmentsList.reloadData()
				} catch let error as NSError {
					if let window = self.windowForSheet {
						NSApp.presentError(error, modalFor: window, delegate: nil, didPresent: nil, contextInfo: nil)
					} else {
						NSApp.presentError(error)
					}
				}
			}
		}
	}
}

extension Document: NSCollectionViewDataSource {
	func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
		let attachment = attachedFiles![indexPath.item]
		let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "AttachmentCell"), for: indexPath) as! AttachmentCell
		item.imageView?.image = attachment.thumbnailImage
		item.textField?.stringValue = attachment.fileExtension ?? ""
		item.delegate = self
		return item
	}
	
	func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
		return attachedFiles?.count ?? 0
	}
}

extension FileWrapper {
	dynamic var fileExtension: String? {
		return preferredFilename?.components(separatedBy: ".").last
	}
	
	dynamic var thumbnailImage: NSImage {
		if let fileExtension = self.fileExtension {
			return NSWorkspace.shared.icon(forFileType: fileExtension)
		} else {
			return NSWorkspace.shared.icon(forFileType: "")
		}
	}
	
	func conforms(to type: CFString) -> Bool {
		guard let fileExtension = self.fileExtension else {
			return false
		}
		guard let fileType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil)?.takeRetainedValue() else {
			return false
		}
		return UTTypeConformsTo(fileType, type)
	}
}

protocol AttachmentCellDelegate: NSObjectProtocol {
	func openSelectedAttachment(collectionViewItem: NSCollectionViewItem)
}

extension Document: AttachmentCellDelegate {
	func openSelectedAttachment(collectionViewItem: NSCollectionViewItem) {
		guard let selectedIndex = attachmentsList.indexPath(for: collectionViewItem)?.item else {
			return
		}
		guard let attachment = attachedFiles?[selectedIndex] else {
			return
		}
		autosave(withImplicitCancellability: false) { error in
			if attachment.conforms(to: kUTTypeJSON), let data = attachment.regularFileContents, let json = try? JSONSerialization.jsonObject(with: data, options: .init()) as? NSDictionary {
				if let latitude = json["latitude"] as? CLLocationDegrees, let longitude = json["longitude"] as? CLLocationDegrees {
					let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
					let placemark = MKPlacemark(coordinate: coordinate)
					let mapItem = MKMapItem(placemark: placemark)
					mapItem.openInMaps(launchOptions: nil)
				}
			} else {
				let url = self.fileURL?.appendingPathComponent(DocumentFileNames.attachmentsDirectory.rawValue, isDirectory: true).appendingPathComponent(attachment.preferredFilename!)
				if let path = url?.path {
					NSWorkspace.shared.openFile(path, withApplication: nil, andDeactivate: true)
				}
			}
		}
	}
}
