//
//  SimpleResultResponse.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//

import Foundation

struct SimpleResultResponse: Decodable {
    let result: Bool
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case result = "result"
        case success = "success"
        case message = "message"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        func decodeBool(key: CodingKeys) -> Bool? {
            if let val = try? container.decode(Bool.self, forKey: key) { return val }
            if let str = try? container.decode(String.self, forKey: key) {
                return ["true", "1", "y", "success"].contains(str.lowercased())
            }
            if let num = try? container.decode(Int.self, forKey: key) {
                return num == 1
            }
            return nil
        }
        
        if let val = decodeBool(key: .result) {
            result = val
        } else if let val = decodeBool(key: .success) {
            result = val
        } else {
            // Default to true if neither key is found but we got a 2xx response
            result = true
        }
        
        message = try? container.decode(String.self, forKey: .message)
    }
}
