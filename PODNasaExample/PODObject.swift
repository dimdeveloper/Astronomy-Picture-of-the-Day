//
//  PODObject.swift
//  PODNasaExample
//
//  Created by TheMacUser on 20.03.2021.
//

import Foundation
struct PODObject: Codable {
    var description: String
    var title: String
    var imageURL: String
    var hdImageURL: String?
    var mediaType: String
    
    enum CodingKeys: String, CodingKey {
        case description = "explanation"
        case title
        case imageURL = "url"
        case hdImageURL = "hdurl"
        case mediaType = "media_type"
    }
    init(description: String, title: String, imageURL: String, hdImageURL: String?, mediaType: String){
        self.description = description
        self.title = title
        self.imageURL = imageURL
        self.hdImageURL = hdImageURL
        self.mediaType = mediaType
        
        
    }
    init(from decoder: Decoder) throws {
        let valueContainer = try decoder.container(keyedBy: CodingKeys.self)
        self.description = try valueContainer.decode(String.self, forKey: CodingKeys.description)
        self.title = try valueContainer.decode(String.self, forKey: CodingKeys.title)
        self.imageURL = try valueContainer.decode(String.self, forKey: CodingKeys.imageURL)
        self.hdImageURL = try? valueContainer.decode(String.self, forKey: CodingKeys.hdImageURL)
        self.mediaType = try valueContainer.decode(String.self, forKey: CodingKeys.mediaType)
    }
}

