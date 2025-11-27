//
//  ApiError.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

enum ApiError: Error {
    case invalidURL
    case requestFailed(statusCode: Int, data: Data?)
    case decodingFailed
    case unknown(Error)
}
