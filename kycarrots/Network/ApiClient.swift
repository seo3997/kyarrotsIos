//
//  ApiClient.swift
//  kycarrots
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

        // =================================================
        // MARK: 🔥 공통 REQUEST LOG
        // =================================================
        #if DEBUG
        print("\n================================================================")
        print("➡️ [REQUEST] \(endpoint.method.rawValue) \(url.absoluteString)")
        if let headers = request.allHTTPHeaderFields {
            print("📝 Headers: \(headers)")
        }
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            print("📤 Body: \(bodyString)")
        } else {
            print("📤 Body: (none)")
        }
        print("================================================================\n")
        #endif

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ApiError.unknown(error)
        }

        // =================================================
        // MARK: 🔥 공통 RESPONSE LOG
        // =================================================
        #if DEBUG
        if let http = response as? HTTPURLResponse {
            print("⬅️ [RESPONSE] \(http.statusCode) \(url.absoluteString)")
        }
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 JSON Response:\n\(jsonString)")
        } else {
            print("📦 Raw Data (non-UTF8, length: \(data.count))")
        }
        print("================================================================\n")
        #endif

        guard let http = response as? HTTPURLResponse else {
            throw ApiError.requestFailed(statusCode: -1, data: data)
        }

        guard (200..<300).contains(http.statusCode) else {
            throw ApiError.requestFailed(statusCode: http.statusCode, data: data)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("❌ Decoding error:", error)
            throw ApiError.decodingFailed
        }
    }

    // =================================================
    // MARK: - Multipart Upload
    // =================================================
    func uploadMultipart<T: Decodable>(
        _ endpoint: AdApiEndpoint,
        as type: T.Type
    ) async throws -> T {

        let url = NetworkConfig.baseURL.appendingPathComponent(endpoint.path)
        let boundary = "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let token = NetworkConfig.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        var builder = MultipartBuilder(boundary: boundary)
        let stamp = String(Int(Date().timeIntervalSince1970))

        switch endpoint {
        case let .registerAdvertise(product, imageMetas, images),
             let .updateAdvertise(product, imageMetas, images):
            // Original Advertise logic
            try builder.addJSON(name: "product", encodable: product)
            try builder.addJSON(name: "imageMetas", encodable: imageMetas)
            builder.addFiles(name: "images", files: images, fileNamePrefix: "img_\(stamp)", mimeType: "image/jpeg")

        case let .insertReview(_, _, _, _, _, images),
             let .updateReview(_, _, _, _, _, images):
            // Review logic: Fields are from query, Images use "reviewFile"
            if let query = endpoint.query {
                for (key, value) in query {
                    builder.addField(name: key, value: value)
                }
            }
            if let imageData = images {
                builder.addFiles(name: "reviewFile", files: imageData, fileNamePrefix: "rev_\(stamp)", mimeType: "image/jpeg")
            }

        default:
            throw ApiError.invalidURL
        }

        request.httpBody = builder.build()

        #if DEBUG
        print("\n================================================================")
        print("➡️ [MULTIPART REQUEST] \(endpoint.method.rawValue) \(url.absoluteString)")
        print("📤 Multipart body length: \(request.httpBody?.count ?? 0) bytes")
        print("================================================================\n")
        #endif

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ApiError.unknown(error)
        }

        #if DEBUG
        if let http = response as? HTTPURLResponse {
            print("⬅️ [MULTIPART RESPONSE] \(http.statusCode) \(url.absoluteString)")
        }
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 JSON Response:\n\(jsonString)")
        }
        print("================================================================\n")
        #endif

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ApiError.requestFailed(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1, data: data)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("❌ Decoding error:", error)
            throw ApiError.decodingFailed
        }
    }

    func requestVoid(_ endpoint: Endpoint) async throws {
        _ = try await request(endpoint, as: EmptyResponse.self)
    }
}

private struct EmptyResponse: Decodable {}

private struct MultipartBuilder {
    let boundary: String
    private var body = Data()

    init(boundary: String) { self.boundary = boundary }

    @discardableResult
    mutating func addField(name: String, value: String) -> Self {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        body.append(value.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        return self
    }

    @discardableResult
    mutating func addJSON(name: String, encodable: Encodable) throws -> Self {
        let json = try JSONEncoder().encode(MultipartAnyEncodable(encodable))
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        body.append(json)
        body.append("\r\n".data(using: .utf8)!)
        return self
    }

    @discardableResult
    mutating func addFiles(
        name: String,
        files: [Data],
        fileNamePrefix: String,
        mimeType: String
    ) -> Self {
        for (i, file) in files.enumerated() {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileNamePrefix)_\(i).jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(file)
            body.append("\r\n".data(using: .utf8)!)
        }
        return self
    }

    func build() -> Data {
        var out = body
        out.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return out
    }
}

private struct MultipartAnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ base: Encodable) { _encode = base.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}

