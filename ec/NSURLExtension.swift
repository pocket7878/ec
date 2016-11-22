//
//  NSURLExtension.swift
//  ec
//
//  Created by 十亀眞怜 on 2016/07/31.
//  Copyright © 2016年 十亀眞怜. All rights reserved.
//

import Foundation

extension URL {
    var fragments: [String : String] {
        var results: [String : String] = [:]
        guard let urlComponents = URLComponents(string: self.absoluteString), let items = urlComponents.queryItems else {
            return results
        }
        
        for item in items {
            results[item.name] = item.value
        }
        
        return results
    }
}
