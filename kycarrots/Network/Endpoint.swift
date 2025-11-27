//
//  Endpoint.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

protocol Endpoint {
    var path: String { get }
    var method: HttpMethod { get }
    var query: [String: String]? { get }
    var body: Encodable? { get }
    var headers: [String: String]? { get }
}

extension Endpoint {
    var query: [String: String]? { nil }
    var body: Encodable? { nil }
    var headers: [String: String]? { nil }
}

/// Encodable wrapping helper
struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init(_ encodable: Encodable) {
        self._encode = encodable.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
