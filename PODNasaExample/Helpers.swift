//
//  Helpers.swift
//  PODNasaExample
//
//  Created by TheMacUser on 20.03.2021.
//

import Foundation
extension URL {
    func withQueries(_ queries: [String: String]) -> URL? {
        var components = URLComponents(url: self,
        resolvingAgainstBaseURL: true)
        components?.queryItems = queries.map
{ URLQueryItem(name: $0.0, value: $0.1) }
        return components?.url
    }
}
extension Date {
    func convertToString() -> String{
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter
        }()
        return dateFormatter.string(from: self)
    }
    func yesterday() -> Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: self)!
    }
    func tomorrow() -> Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: self)!
    }
}
