//
//  AdItem.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

struct AdItem: Decodable {
    let productId: String
    let title: String
    let description: String
    let price: String
    let imageUrl: String
    let userId: String
}
