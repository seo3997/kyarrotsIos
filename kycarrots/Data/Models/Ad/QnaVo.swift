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

    init(
        qnaId: String? = nil,
        productId: String? = nil,
        userNo: String? = nil,
        userNm: String? = nil,
        title: String? = nil,
        contents: String? = nil,
        secretYn: String? = nil,
        registDt: String? = nil,
        qnaStatus: String? = nil,
        answerContents: String? = nil,
        answererNm: String? = nil,
        answeredAt: String? = nil
    ) {
        self.qnaId = qnaId
        self.productId = productId
        self.userNo = userNo
        self.userNm = userNm
        self.title = title
        self.contents = contents
        self.secretYn = secretYn
        self.registDt = registDt
        self.qnaStatus = qnaStatus
        self.answerContents = answerContents
        self.answererNm = answererNm
        self.answeredAt = answeredAt
    }

    enum CodingKeys: String, CodingKey {
        case qnaId = "QNA_ID"
        case productId = "PRODUCT_ID"
        case userNo = "USER_NO"
        case userNm = "USER_NM"
        case title = "TITLE"
        case contents = "CONTENTS"
        case secretYn = "SECRET_YN"
        case registDt = "REGIST_DT"
        case qnaStatus = "QNA_STATUS"
        case answerContents = "ANSWER_CONTENTS"
        case answererNm = "ANSWERER_NM"
        case answeredAt = "ANSWERED_AT"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle QNA_ID as String or Int64
        if let qId = try? container.decodeIfPresent(String.self, forKey: .qnaId) {
            qnaId = qId
        } else if let qIdInt = try? container.decodeIfPresent(Int64.self, forKey: .qnaId) {
            qnaId = String(qIdInt)
        } else {
            qnaId = nil
        }
            
        // Handle PRODUCT_ID as String or Int64
        if let pId = try? container.decodeIfPresent(String.self, forKey: .productId) {
            productId = pId
        } else if let pIdInt = try? container.decodeIfPresent(Int64.self, forKey: .productId) {
            productId = String(pIdInt)
        } else {
            productId = nil
        }
            
        // Handle USER_NO as String or Int64
        if let uNo = try? container.decodeIfPresent(String.self, forKey: .userNo) {
            userNo = uNo
        } else if let uNoInt = try? container.decodeIfPresent(Int64.self, forKey: .userNo) {
            userNo = String(uNoInt)
        } else {
            userNo = nil
        }
            
        userNm = try container.decodeIfPresent(String.self, forKey: .userNm)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        contents = try container.decodeIfPresent(String.self, forKey: .contents)
        secretYn = try container.decodeIfPresent(String.self, forKey: .secretYn)
        registDt = try container.decodeIfPresent(String.self, forKey: .registDt)
        qnaStatus = try container.decodeIfPresent(String.self, forKey: .qnaStatus)
        answerContents = try container.decodeIfPresent(String.self, forKey: .answerContents)
        answererNm = try container.decodeIfPresent(String.self, forKey: .answererNm)
        answeredAt = try container.decodeIfPresent(String.self, forKey: .answeredAt)
    }
}
