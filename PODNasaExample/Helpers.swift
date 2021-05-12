//
//  Helpers.swift
//  PODNasaExample
//
//  Created by TheMacUser on 20.03.2021.
//

import Foundation
import  UIKit

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
extension String {
    func getVideoID() -> String? {
        guard let url = self.removingPercentEncoding else { return nil }
        do {
            let regex = try NSRegularExpression.init(pattern: "((?<=(v|V)/)|(?<=be/)|(?<=(\\?|\\&)v=)|(?<=embed/))([\\w-]++)", options: .caseInsensitive)
            let range = NSRange(location: 0, length: url.count)
            if let matchRange = regex.firstMatch(in: url, options: .reportCompletion, range: range)?.range {
                let matchLength = (matchRange.lowerBound + matchRange.length) - 1
                if range.contains(matchRange.lowerBound) &&
                    range.contains(matchLength) {
                    let start = url.index(url.startIndex, offsetBy: matchRange.lowerBound)
                    let end = url.index(url.startIndex, offsetBy: matchLength)
                    return String(url[start...end])
                }
            }
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
}

