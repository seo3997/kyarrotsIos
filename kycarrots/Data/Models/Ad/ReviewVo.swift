//
//  ReviewVo.swift
//  kycarrots
//
//  Created by soohyun on 03/21/26.
//

import Foundation

struct ReviewVo: Codable, Identifiable {
    var id: String { reviewId ?? UUID().uuidString }
    let reviewId: String?
    let productId: String?
    let userNo: String?
    let userNm: String?
    let rating: Int
    let contents: String?
    let registDt: String?
    let displayYn: String?
    let atchDocId: String?
    let fileRltvPath: String?
}
