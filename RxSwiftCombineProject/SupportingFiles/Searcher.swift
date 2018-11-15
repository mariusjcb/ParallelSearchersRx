//
//  Searcher.swift
//  RxSwiftCombineProject
//
//  Created by Marius Ilie on 15/11/2018.
//  Copyright © 2018 Marius Ilie. All rights reserved.
//

import Foundation
import RxSwift

extension Single where Element == [[String:Any]] {
    var obervableList: Observable<[String:Any]> {
        return self.asObservable().flatMap( { Observable<[String:Any]>.from($0) })
    }
}

enum URLBuilder: String {
    case baseUrl = "https://api.github.com/search/"
    
    case repositories = "repositories"
    case users = "users"
    case topics = "topics"
    case commits = "commits"
    
    func build() -> String {
        return URLBuilder.baseUrl.rawValue + self.rawValue + "?q=%@"
    }
}

class Searcher {
    class func search(_ endpoint: URLBuilder, by filter: String) -> Single<[[String:Any]]> {
        let url = URL(string: String(format: endpoint.build(), filter))!
        
        return Single.create { observer in
            var request = URLRequest(url: url)
            request.addValue("application/vnd.github.mercy-preview+json", forHTTPHeaderField: "Accept")
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard let dataResponse = data, error == nil else {
                    observer(.error(error!))
                    return
                }
                
                do{
                    let jsonResponse = try JSONSerialization.jsonObject(with: dataResponse, options: []) as? [String: Any]
                    
                    if let items = jsonResponse?["items"] as? [[String:Any]] {
                        observer(.success(items))
                    } else {
                        throw NSError(domain: "", code: -1)
                    }
                } catch let error {
                    observer(.error(error))
                }
            }
            
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
}
