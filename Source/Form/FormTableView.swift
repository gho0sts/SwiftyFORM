// MIT license. Copyright (c) 2014 SwiftyFORM. All rights reserved.
import UIKit

public class FormTableView: UITableView {
	public init() {
		super.init(frame: CGRectZero, style: .Grouped)
		contentInset = UIEdgeInsetsZero
		scrollIndicatorInsets = UIEdgeInsetsZero
		estimatedRowHeight = 44.0
	}

	public required init(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
}


extension TableViewSectionArray {

	public func toggleExpandCollapse(toggleCell toggleCell: UITableViewCell, expandedCell: UITableViewCell, tableView: UITableView) {
		SwiftyFormLog("will expand collapse")

		// If the expanded cell already is visible then collapse it
		let whatToCollapse = WhatToCollapse.process(
			expandedCell: expandedCell,
			attemptCollapseAllOtherCells: true,
			sectionArray: self
		)
		print("whatToCollapse: \(whatToCollapse)")
		
		if !whatToCollapse.indexPaths.isEmpty {

			for indexPath in whatToCollapse.indexPaths {
				// TODO: clean up.. don't want to subtract by 1
				let indexPath2 = NSIndexPath(forRow: indexPath.row-1, inSection: indexPath.section)
				assignDefaultColors(indexPath2)
			}
			
			tableView.beginUpdates()
			tableView.deleteRowsAtIndexPaths(whatToCollapse.indexPaths, withRowAnimation: .Fade)
			tableView.endUpdates()
		}
		
		// If the expanded cell is hidden then expand it
		let whatToExpand = WhatToExpand.process(
			expandedCell: expandedCell,
			sectionArray: self,
			isCollapse: whatToCollapse.isCollapse
		)
		print("whatToExpand: \(whatToExpand)")

		if !whatToExpand.indexPaths.isEmpty {
			
			var toggleIndexPath: NSIndexPath?
			if let item = findItem(toggleCell) {
				toggleIndexPath = indexPathForItem(item)
			}
			
			if let cell = toggleCell as? AssignAppearance {
				cell.assignTintColors()
			}
			
			CATransaction.begin()
			CATransaction.setCompletionBlock({
				// Ensure that the toggleCell and expandedCell are visible
				if let indexPath = toggleIndexPath {
					print("scroll to visible: \(indexPath)")
					tableView.form_scrollToVisibleAfterExpand(indexPath)
				}
			})

			tableView.beginUpdates()
			tableView.insertRowsAtIndexPaths(whatToExpand.indexPaths, withRowAnimation: .Fade)
			tableView.endUpdates()
			
			CATransaction.commit()
		}
		
		SwiftyFormLog("did expand collapse")
	}
	
	func assignDefaultColors(indexPath: NSIndexPath) {
		print("assign default colors: \(indexPath)")
		
		guard let item = findVisibleItem(indexPath: indexPath) else {
			print("no visible cell for indexPath: \(indexPath)")
			return
		}
		
		if let cell = item.cell as? AssignAppearance {
			cell.assignDefaultColors()
		}
	}
}


struct WhatToCollapse {
	let indexPaths: [NSIndexPath]
	let isCollapse: Bool
	
	static func process(expandedCell expandedCell: UITableViewCell, attemptCollapseAllOtherCells: Bool, sectionArray: TableViewSectionArray) -> WhatToCollapse {
		var indexPaths = [NSIndexPath]()
		var isCollapse = false
		
		// If the expanded cell already is visible then collapse it
		for (sectionIndex, section) in sectionArray.sections.enumerate() {
			for (row, item) in section.cells.visibleItems.enumerate() {
				if item.cell === expandedCell {
					item.hidden = true
					indexPaths.append(NSIndexPath(forRow: row, inSection: sectionIndex))
					isCollapse = true
					continue
				}
				if attemptCollapseAllOtherCells {
					if let expandedCell = item.cell as? DatePickerCellExpanded { // TODO: remove hardcoded type
						if let collapsedCell = expandedCell.collapsedCell {
							// If it's behavior is AlwaysExpanded, then we don't want it collapsed
							if collapsedCell.model.expandCollapseWhenSelectingRow {
								item.hidden = true
								indexPaths.append(NSIndexPath(forRow: row, inSection: sectionIndex))
							}
						}
					}
				}
			}
		}
		
		if !indexPaths.isEmpty {
			sectionArray.reloadVisibleItems()
		}
		return WhatToCollapse(indexPaths: indexPaths, isCollapse: isCollapse)
	}
}


struct WhatToExpand {
	let indexPaths: [NSIndexPath]
	
	static func process(expandedCell expandedCell: UITableViewCell, sectionArray: TableViewSectionArray, isCollapse: Bool) -> WhatToExpand {
		var indexPaths = [NSIndexPath]()
		
		// If the expanded cell is hidden then expand it
		if !isCollapse {
			if let item = sectionArray.findItem(expandedCell) {
				if item.hidden {
					item.hidden = false
					sectionArray.reloadVisibleItems()
					
					if let indexPath = sectionArray.indexPathForItem(item) {
						indexPaths.append(indexPath)
					}
				}
			}
		}
		
		return WhatToExpand(indexPaths: indexPaths)
	}
}
