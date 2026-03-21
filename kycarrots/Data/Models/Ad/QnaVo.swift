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
        case qnaId
        case productId
        case userNo
        case userNm
        case title
        case contents
        case secretYn
        case registDt
        case qnaStatus
        case answerContents
        case answererNm
        case answeredAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        qnaId = (try? container.decodeIfPresent(String.self, forKey: .qnaId))
            ?? (try? container.decodeIfPresent(Int64.self, forKey: .qnaId)).map { String($0) }
            
        productId = (try? container.decodeIfPresent(String.self, forKey: .productId))
            ?? (try? container.decodeIfPresent(Int64.self, forKey: .productId)).map { String($0) }
            
        userNo = (try? container.decodeIfPresent(String.self, forKey: .userNo))
            ?? (try? container.decodeIfPresent(Int64.self, forKey: .userNo)).map { String($0) }
            
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
