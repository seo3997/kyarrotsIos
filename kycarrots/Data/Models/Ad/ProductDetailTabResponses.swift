//
//  ReviewListResponse.swift
//  kycarrots
//

import Foundation

struct ReviewListResponse: Decodable {
    let list: [ReviewVo]?
    let data: [ReviewVo]?
    
    var reviews: [ReviewVo] {
        list ?? data ?? []
    }
}

struct QnaListResponse: Decodable {
    let list: [QnaVo]?
    
    var qnas: [QnaVo] {
        list ?? []
    }
}
