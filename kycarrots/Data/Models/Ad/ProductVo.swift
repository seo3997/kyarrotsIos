//
//  ProductVo.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//

import Foundation

struct ProductVo: Codable {
    let productId: String?
    let userNo: String?
    let title: String
    let description: String?
    let price: String?
    let categoryGroup: String?
    let categoryMid: String?
    let categoryScls: String?
    let saleStatus: String?
    let areaGroup: String?
    let areaMid: String?
    let areaScls: String?
    let quantity: String?
    let unitGroup: String?
    let unitCode: String?
    let desiredShippingDate: String?
    let registerNo: String?
    let registDt: String?
    let updusrNo: String?
    let updtDt: String?
    let imageUrl: String?

    let categoryMidNm: String?
    let categorySclsNm: String?
    let areaMidNm: String?
    let areaSclsNm: String?
    let unitCodeNm: String?
    let saleStatusNm: String?
    let userId: String?
    let wholesalerNo: String?
    let wholesalerId: String?
    let fav: String?
    let systemType: String?
    let rejectReason: String?
    let branchId: String?
    let editorMode: String?
    let availableQuantity: String?

    init(
        productId: String? = nil,
        userNo: String? = nil,
        title: String,
        description: String? = nil,
        price: String? = nil,
        categoryGroup: String? = nil,
        categoryMid: String? = nil,
        categoryScls: String? = nil,
        saleStatus: String? = nil,
        areaGroup: String? = nil,
        areaMid: String? = nil,
        areaScls: String? = nil,
        quantity: String? = nil,
        unitGroup: String? = nil,
        unitCode: String? = nil,
        desiredShippingDate: String? = nil,
        registerNo: String? = nil,
        registDt: String? = nil,
        updusrNo: String? = nil,
        updtDt: String? = nil,
        imageUrl: String? = nil,
        categoryMidNm: String? = nil,
        categorySclsNm: String? = nil,
        areaMidNm: String? = nil,
        areaSclsNm: String? = nil,
        unitCodeNm: String? = nil,
        saleStatusNm: String? = nil,
        userId: String? = nil,
        wholesalerNo: String? = nil,
        wholesalerId: String? = nil,
        fav: String? = nil,
        systemType: String? = nil,
        rejectReason: String? = nil,
        branchId: String? = nil,
        editorMode: String? = nil,
        availableQuantity: String? = nil
    ) {
        self.productId = productId
        self.userNo = userNo
        self.title = title
        self.description = description
        self.price = price
        self.categoryGroup = categoryGroup
        self.categoryMid = categoryMid
        self.categoryScls = categoryScls
        self.saleStatus = saleStatus
        self.areaGroup = areaGroup
        self.areaMid = areaMid
        self.areaScls = areaScls
        self.quantity = quantity
        self.unitGroup = unitGroup
        self.unitCode = unitCode
        self.desiredShippingDate = desiredShippingDate
        self.registerNo = registerNo
        self.registDt = registDt
        self.updusrNo = updusrNo
        self.updtDt = updtDt
        self.imageUrl = imageUrl
        self.categoryMidNm = categoryMidNm
        self.categorySclsNm = categorySclsNm
        self.areaMidNm = areaMidNm
        self.areaSclsNm = areaSclsNm
        self.unitCodeNm = unitCodeNm
        self.saleStatusNm = saleStatusNm
        self.userId = userId
        self.wholesalerNo = wholesalerNo
        self.wholesalerId = wholesalerId
        self.fav = fav
        self.systemType = systemType
        self.rejectReason = rejectReason
        self.branchId = branchId
        self.editorMode = editorMode
        self.availableQuantity = availableQuantity
    }

    enum CodingKeys: String, CodingKey {
        case productId
        case userNo
        case title
        case description
        case price
        case categoryGroup
        case categoryMid
        case categoryScls
        case saleStatus
        case areaGroup
        case areaMid
        case areaScls
        case quantity
        case unitGroup
        case unitCode
        case desiredShippingDate
        case registerNo
        case registDt
        case updusrNo
        case updtDt
        case imageUrl
        case categoryMidNm
        case categorySclsNm
        case areaMidNm
        case areaSclsNm
        case unitCodeNm
        case saleStatusNm
        case userId
        case wholesalerNo
        case wholesalerId
        case fav
        case systemType
        case rejectReason
        case branchId
        case editorMode
        case availableQuantity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        productId = (try? container.decodeIfPresent(String.self, forKey: .productId)) ?? (try? container.decodeIfPresent(Int64.self, forKey: .productId)).map { String($0) }
        userNo = (try? container.decodeIfPresent(String.self, forKey: .userNo)) ?? (try? container.decodeIfPresent(Int64.self, forKey: .userNo)).map { String($0) }
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description)
        price = (try? container.decodeIfPresent(String.self, forKey: .price)) ?? (try? container.decodeIfPresent(Int64.self, forKey: .price)).map { String($0) }
        categoryGroup = try container.decodeIfPresent(String.self, forKey: .categoryGroup)
        categoryMid = try container.decodeIfPresent(String.self, forKey: .categoryMid)
        categoryScls = try container.decodeIfPresent(String.self, forKey: .categoryScls)
        saleStatus = try container.decodeIfPresent(String.self, forKey: .saleStatus)
        areaGroup = try container.decodeIfPresent(String.self, forKey: .areaGroup)
        areaMid = try container.decodeIfPresent(String.self, forKey: .areaMid)
        areaScls = try container.decodeIfPresent(String.self, forKey: .areaScls)
        quantity = (try? container.decodeIfPresent(String.self, forKey: .quantity)) ?? (try? container.decodeIfPresent(Int64.self, forKey: .quantity)).map { String($0) }
        unitGroup = try container.decodeIfPresent(String.self, forKey: .unitGroup)
        unitCode = try container.decodeIfPresent(String.self, forKey: .unitCode)
        desiredShippingDate = try container.decodeIfPresent(String.self, forKey: .desiredShippingDate)
        registerNo = (try? container.decodeIfPresent(String.self, forKey: .registerNo)) ?? (try? container.decodeIfPresent(Int64.self, forKey: .registerNo)).map { String($0) }
        registDt = try container.decodeIfPresent(String.self, forKey: .registDt)
        updusrNo = (try? container.decodeIfPresent(String.self, forKey: .updusrNo)) ?? (try? container.decodeIfPresent(Int64.self, forKey: .updusrNo)).map { String($0) }
        updtDt = try container.decodeIfPresent(String.self, forKey: .updtDt)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        categoryMidNm = try container.decodeIfPresent(String.self, forKey: .categoryMidNm)
        categorySclsNm = try container.decodeIfPresent(String.self, forKey: .categorySclsNm)
        areaMidNm = try container.decodeIfPresent(String.self, forKey: .areaMidNm)
        areaSclsNm = try container.decodeIfPresent(String.self, forKey: .areaSclsNm)
        unitCodeNm = try container.decodeIfPresent(String.self, forKey: .unitCodeNm)
        saleStatusNm = try container.decodeIfPresent(String.self, forKey: .saleStatusNm)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        wholesalerNo = try container.decodeIfPresent(String.self, forKey: .wholesalerNo)
        wholesalerId = try container.decodeIfPresent(String.self, forKey: .wholesalerId)
        fav = (try? container.decodeIfPresent(String.self, forKey: .fav)) ?? (try? container.decodeIfPresent(Int64.self, forKey: .fav)).map { String($0) }
        systemType = try container.decodeIfPresent(String.self, forKey: .systemType)
        rejectReason = try container.decodeIfPresent(String.self, forKey: .rejectReason)
        branchId = try container.decodeIfPresent(String.self, forKey: .branchId)
        
        // editorMode as String or Int64
        editorMode = (try? container.decodeIfPresent(String.self, forKey: .editorMode)) ?? (try? container.decodeIfPresent(Int64.self, forKey: .editorMode)).map { String($0) }
        
        availableQuantity = (try? container.decodeIfPresent(String.self, forKey: .availableQuantity)) ?? (try? container.decodeIfPresent(Int64.self, forKey: .availableQuantity)).map { String($0) }
    }
}
