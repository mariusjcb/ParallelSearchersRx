//
//  ViewController.swift
//  RxSwiftCombineProject
//
//  Created by Marius Ilie on 15/11/2018.
//  Copyright © 2018 Marius Ilie. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Kingfisher

class ViewController: UIViewController {
    
    private var disposeBag = DisposeBag()
    @IBOutlet private weak var tableView: UITableView!
    
    private lazy var datasourceAdapter = TableViewItemAdapter(target: self)
    private var searchTerms: [(URLBuilder, String)] = [
        (.users, "obama"),
        (.users, "mariusjcb"),
        (.repositories, "sbuzoianu"),
        (.users, "sbuzoianu"),
        (.repositories, "trump"),
        (.repositories, "heimdallos"),
        (.repositories, "marvel"),
        (.repositories, "ios"),
        (.repositories, "nazi"),
        (.repositories, "gta"),
        (.topics, "romania")]
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        disposeBag = DisposeBag()
        datasourceAdapter.sections = searchTerms.map { $0.0.rawValue + " - " + $0.1 }
        
        // Combine requests
        Observable.combineLatest(getSearchers())
            .materialize()
            .filter { $0.event.element != nil }
            .map { $0.element! }
            .bind(to: tableView.rx.items(dataSource: datasourceAdapter))
            .disposed(by: disposeBag)
        
        // Open url on select
        tableView.rx.modelSelected([String:Any].self)
            .subscribe(onNext: openUrl)
            .disposed(by: disposeBag)
    }
    
}

extension ViewController: TableViewAdapterTarget {
    func load(_ targetItem: TableViewTargetItem) {
        let item = targetItem.item
        let cell = targetItem.cell
        
        let itemTitle = item["login"] ?? item["full_name"] ?? item["name"]
        let itemDesc = item["description"] ?? item["created_at"]
        let itemIcon = item["avatar_url"] as? String
        
        cell.textLabel?.text = itemTitle as? String
        cell.detailTextLabel?.text = itemDesc as? String
        cell.imageView?.kf.setImage(with: URL(string: itemIcon ?? ""))
    }
}

extension ViewController {
    fileprivate func openUrl(_ item: [String: Any]) {
        tableView.deselectRow(at: tableView.indexPathForSelectedRow!, animated: true)
        guard let urlStr = item["html_url"] as? String, let url = URL(string: urlStr) else { return }
        
        UIApplication.shared.open(url)
    }
    
    fileprivate func getSearchers() -> [Observable<[[String : Any]]>] {
        return searchTerms.map { (endpoint, term) in
            Searcher.search(endpoint, by: term)
                .catchErrorJustReturn([])
                .obervableList
                .take(2)
                .toArray()
                .startWith([])
        }
    }
}
