//
//  ProductImageVo.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

struct ProductImageVo: Codable {
    let imageId: String?
    let productId: String?
    let imageCd: String?
    let imageUrl: String?
    let imageName: String?
    let represent: String
    let imageSize: Int64?
    let imageText: String?
    let imageType: String?
    let registerNo: String
    let registDt: String?
    let updusrNo: String
    let updtDt: String?
}
