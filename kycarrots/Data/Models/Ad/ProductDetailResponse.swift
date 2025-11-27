//
//  ProductDetailResponse.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

struct ProductDetailResponse: Decodable {
    let product: ProductVo
    let imageMetas: [ProductImageVo]
}
