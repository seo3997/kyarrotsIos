//
//  ApiClient.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

final class ApiClient {
    static let shared = ApiClient()
    private init() {}

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    func request<T: Decodable>(_ endpoint: Endpoint,
                               as type: T.Type) async throws -> T {
        var url = NetworkConfig.baseURL.appendingPathComponent(endpoint.path)

        // query
        if let query = endpoint.query, !query.isEmpty {
            var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
            comps?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
            guard let final = comps?.url else { throw ApiError.invalidURL }
            url = final
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        // 공통 헤더
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = NetworkConfig.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // 개별 헤더
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        // body
        if let body = endpoint.body {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ApiError.unknown(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ApiError.requestFailed(statusCode: -1, data: data)
        }

        guard (200..<300).contains(http.statusCode) else {
            throw ApiError.requestFailed(statusCode: http.statusCode, data: data)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Decoding error:", error)
            throw ApiError.decodingFailed
        }
    }

    func requestVoid(_ endpoint: Endpoint) async throws {
        _ = try await request(endpoint, as: EmptyResponse.self)
    }
}

private struct EmptyResponse: Decodable {}
