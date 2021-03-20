//
//  Requests.swift
//  PODNasaExample
//
//  Created by TheMacUser on 20.03.2021.
//

import Foundation
struct Requests {
    let key = "9XtsiV62YUJ2d0Xs0ZxCb10H0GA00BZzz0TxudeM"
    let baseURL = URL(string: "https://api.nasa.gov/planetary/apod")!
    
    func fetchNASAPOD(date: Date, completion: @escaping (PODObject?) -> Void) {
        let stringDate = date.convertToString()
        let query = [
            "api_key" : "\(key)",
            "date" : stringDate
        ]
        let requestURL = baseURL.withQueries(query)!
        let task = URLSession.shared.dataTask(with: requestURL) { (data, responce, error) in
            if let data = data {
                let jsonDecoder = JSONDecoder()
                do {
                    let retreivedData = try jsonDecoder.decode(PODObject.self, from: data)
                        completion(retreivedData)
                }
                catch {
                    print("Cant decode data!")
                }
                
            } else {
                print("There is no Data!")
            }
        }
        task.resume()
    }
}
