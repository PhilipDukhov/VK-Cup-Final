//
//  URL+appendingQueryParameters.swift
//  Store
//
//  Created by Philip Dukhov on 10/29/20.
//

import Foundation

extension Dictionary {
    /**
     This computed property returns a query parameters string from the given NSDictionary. For
     example, if the input is @{@"day":@"Tuesday", @"month":@"January"}, the output
     string will be @"day=Tuesday&month=January".
     @return The computed parameters string.
     */
    var queryParameters: String {
        compactMap { key, value in
            return String(format: "%@=%@",
                          String(describing: key).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!,
                          String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
        }.joined(separator: "&")
    }
}

extension URL {
    /**
     Creates a new URL by adding the given query parameters.
     @param parametersDictionary The query parameter dictionary to add.
     @return A new URL.
     */
    mutating func appendQueryParameters(_ parametersDictionary: [String: String]) {
        self = self.appendingQueryParameters(parametersDictionary)
    }
    
    func appendingQueryParameters(_ parametersDictionary: [String: String]) -> URL {
        URL(string: String(format: "%@?%@", self.absoluteString, parametersDictionary.queryParameters))!
    }
}
