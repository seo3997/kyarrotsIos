//
//  AdResponse.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

struct AdResponse: Decodable {
    let adItems: [AdItem]

    enum CodingKeys: String, CodingKey {
        case items, list, data, content
    }

    init(from decoder: Decoder) throws {
        // 1. Try to decode as a direct array [AdItem]
        if let array = try? decoder.singleValueContainer().decode([AdItem].self) {
            self.adItems = array
            return
        }

        // 2. Try to decode as an object with specific keys
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let items = try? container.decode([AdItem].self, forKey: .items) {
            self.adItems = items
        } else if let list = try? container.decode([AdItem].self, forKey: .list) {
            self.adItems = list
        } else if let data = try? container.decode([AdItem].self, forKey: .data) {
            self.adItems = data
        } else if let content = try? container.decode([AdItem].self, forKey: .content) {
            self.adItems = content
        } else {
            self.adItems = []
        }
    }
}
