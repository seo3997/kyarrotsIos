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
        
        // Try to get result from "result" or "success" key
        if let val = try? container.decode(Bool.self, forKey: .result) {
            result = val
        } else if let val = try? container.decode(Bool.self, forKey: .success) {
            result = val
        } else {
            // Default to false if neither key is found or decoding fails
            result = false
        }
        
        message = try? container.decode(String.self, forKey: .message)
    }
}
