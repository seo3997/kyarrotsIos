//
//  ProductImageVo.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//

import Foundation

struct ProductImageVo: Codable {
    let imageId: Int64?
    let productId: Int64
    let imageCd: String?
    let imageUrl: String?
    let imageName: String?
    let represent: Int
    let imageSize: Int64?
    let imageText: String?
    let imageType: String?
    let registerNo: Int64
    let registDt: String?
    let updusrNo: Int64
    let updtDt: String?

    init(
        imageId: Int64? = nil,
        productId: Int64 = 0,
        imageCd: String? = nil,
        imageUrl: String? = nil,
        imageName: String? = nil,
        represent: Int = 0,
        imageSize: Int64? = nil,
        imageText: String? = nil,
        imageType: String? = nil,
        registerNo: Int64 = 0,
        registDt: String? = nil,
        updusrNo: Int64 = 0,
        updtDt: String? = nil
    ) {
        self.imageId = imageId
        self.productId = productId
        self.imageCd = imageCd
        self.imageUrl = imageUrl
        self.imageName = imageName
        self.represent = represent
        self.imageSize = imageSize
        self.imageText = imageText
        self.imageType = imageType
        self.registerNo = registerNo
        self.registDt = registDt
        self.updusrNo = updusrNo
        self.updtDt = updtDt
    }

    enum CodingKeys: String, CodingKey {
        case imageId
        case productId
        case imageCd
        case imageUrl
        case imageName
        case represent
        case imageSize
        case imageText
        case imageType
        case registerNo
        case registDt
        case updusrNo
        case updtDt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Flexible decoding for numeric IDs to Int64
        imageId = (try? container.decodeIfPresent(Int64.self, forKey: .imageId)) 
            ?? (try? container.decodeIfPresent(String.self, forKey: .imageId)).flatMap { Int64($0) }
            
        productId = (try? container.decodeIfPresent(Int64.self, forKey: .productId)) 
            ?? (try? container.decodeIfPresent(String.self, forKey: .productId)).flatMap { Int64($0) } ?? 0
            
        imageCd = try container.decodeIfPresent(String.self, forKey: .imageCd)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        imageName = try container.decodeIfPresent(String.self, forKey: .imageName)
        
        // Flexible decoding for represent (Int)
        if let rInt = try? container.decodeIfPresent(Int.self, forKey: .represent) {
            represent = rInt
        } else if let rString = try? container.decodeIfPresent(String.self, forKey: .represent) {
            represent = Int(rString) ?? 0
        } else if let rInt64 = try? container.decodeIfPresent(Int64.self, forKey: .represent) {
            represent = Int(rInt64)
        } else {
            represent = 0
        }
        
        imageSize = (try? container.decodeIfPresent(Int64.self, forKey: .imageSize)) 
            ?? (try? container.decodeIfPresent(String.self, forKey: .imageSize)).flatMap { Int64($0) }
            
        imageText = try container.decodeIfPresent(String.self, forKey: .imageText)
        imageType = try container.decodeIfPresent(String.self, forKey: .imageType)
        
        registerNo = (try? container.decodeIfPresent(Int64.self, forKey: .registerNo)) 
            ?? (try? container.decodeIfPresent(String.self, forKey: .registerNo)).flatMap { Int64($0) } ?? 0
            
        registDt = try container.decodeIfPresent(String.self, forKey: .registDt)
        
        updusrNo = (try? container.decodeIfPresent(Int64.self, forKey: .updusrNo)) 
            ?? (try? container.decodeIfPresent(String.self, forKey: .updusrNo)).flatMap { Int64($0) } ?? 0
            
        updtDt = try container.decodeIfPresent(String.self, forKey: .updtDt)
    }
}
