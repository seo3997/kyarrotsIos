//
//  ProductImageVo.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

struct ProductImageVo: Codable {
    let imageId: Int64
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
}
