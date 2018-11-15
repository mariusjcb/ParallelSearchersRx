//
//  TableViewAdapter.swift
//  RxSwiftCombineProject
//
//  Created by Marius Ilie on 15/11/2018.
//  Copyright © 2018 Marius Ilie. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift


class TableViewTargetItem: NSObject {
    let item: [String:Any]
    let cell: UITableViewCell
    
    init(item: [String:Any], cell: UITableViewCell) {
        self.item = item
        self.cell = cell
    }
}

@objc protocol TableViewAdapterTarget: class {
    @objc func load(_ targetItem: TableViewTargetItem)
}

final class TableViewItemAdapter: NSObject, UITableViewDataSource, UITableViewDelegate, RxTableViewDataSourceType, SectionedViewDataSourceType {
    typealias Event = RxSwift.Event
    typealias Element = [[[String: Any]]]
    
    private var items: [[[String: Any]]] = []
    
    private var target: NSObject?
    private var selector: Selector?
    var sections: [String] = []
    
    init(target: NSObject & TableViewAdapterTarget) {
        super.init()
        self.target = target
    }
    
    func model(at indexPath: IndexPath) throws -> Any {
        return items[indexPath.section][indexPath.row]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellID")!
        let item = items[indexPath.section][indexPath.row]
        
        let targetItem = TableViewTargetItem(item: item, cell: cell)
        target?.performSelector(onMainThread: #selector(TableViewAdapterTarget.load(_:)), with: targetItem, waitUntilDone: true)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard sections.count > section else { return "" }
        return items[section].count > 0 ? sections[section] : ""
    }
    
    func tableView(_ tableView: UITableView, observedEvent: Event<[[[String : Any]]]>) {
        Binder(self) { (adapter, items) in
            adapter.items = items
            tableView.reloadData()
            }.on(observedEvent)
    }
}
