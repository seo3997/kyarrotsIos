//
//  TxtListDataInfo.swift
//  kycarrots
//
//  Created by soo on 12/14/25.
//


import Foundation

struct TxtListDataInfo: Codable, Hashable {
    var strIdx: String = ""   // 선택 한 고유 값
    var strMsg: String = ""

    init(strIdx: String = "", strMsg: String = "") {
        self.strIdx = strIdx
        self.strMsg = strMsg
    }
}
