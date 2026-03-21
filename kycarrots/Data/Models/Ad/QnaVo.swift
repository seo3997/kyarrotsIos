//
//  QnaVo.swift
//  kycarrots
//
//  Created by soohyun on 03/21/26.
//

import Foundation

struct QnaVo: Codable, Identifiable {
    var id: String { qnaId ?? UUID().uuidString }
    let qnaId: String?
    let productId: String?
    let userNo: String?
    let userNm: String?
    let title: String?
    let contents: String?
    let secretYn: String?
    let registDt: String?
    let qnaStatus: String?
    let answerContents: String?
    let answererNm: String?
    let answeredAt: String?
}
