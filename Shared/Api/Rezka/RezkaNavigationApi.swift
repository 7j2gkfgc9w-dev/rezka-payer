//
//  NavigationRezkaApi.swift
//  rezka-player
//
//  Created by Vitalii Parovishnyk on 21.10.2022.
//

import Foundation

struct NavigationRezkaApi {

    private let session = URLSession.shared
    
    func fetch() async throws -> [CategoryList] {
        try await fetchNavigation(from: generateNavigationUrl())
    }
    
    private func fetchNavigation(from url: URL) async throws -> [CategoryList] {
        let request = request(for: url)
        
        let data: Data
        let urlResponse: URLResponse
        do {
            (data, urlResponse) = try await session.data(for: request)
        } catch {
            let ns = error as NSError
            let failingURL = (ns.userInfo[NSURLErrorFailingURLErrorKey] as? URL)?.absoluteString
                ?? (ns.userInfo[NSURLErrorFailingURLStringErrorKey] as? String)
                ?? url.absoluteString
            throw NSError(
                domain: "RezkaNetwork",
                code: ns.code,
                userInfo: [NSLocalizedDescriptionKey: "GW 1.2\nNET \(ns.domain) \(ns.code)\n\(failingURL)\n\(ns.localizedDescription)"]
            )
        }

        guard let response = urlResponse as? HTTPURLResponse else {
            throw DataError.generate(for: .navigationRezkaApi, error: .bad)
        }

        let html = String(decoding: data, as: UTF8.self)
        let title = html.range(of: "<title>", options: .caseInsensitive).flatMap { start in
            html.range(of: "</title>", options: .caseInsensitive, range: start.upperBound..<html.endIndex).map { end in
                String(html[start.upperBound..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } ?? "(no title)"

        guard (200...299).contains(response.statusCode) else {
            throw NSError(
                domain: "RezkaHTTP",
                code: response.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "GW 1.2\nHTTP \(response.statusCode)\n\(url.absoluteString)\nTitle: \(title)"]
            )
        }

        guard !html.isEmpty else {
            throw DataError.generate(for: .navigationRezkaApi, error: .empty)
        }

        do {
            let categories = try NavigationRezkaApiResponse(from: html).categories
            guard !categories.isEmpty else {
                throw NSError(domain: "RezkaParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "GW 1.2\nPARSER EMPTY\n\(url.absoluteString)\nTitle: \(title)"])
            }
            return categories
        } catch {
            let ns = error as NSError
            throw NSError(domain: "RezkaParser", code: ns.code, userInfo: [NSLocalizedDescriptionKey: "GW 1.2\nPARSER \(ns.localizedDescription)\n\(url.absoluteString)\nTitle: \(title)"])
        }
    }
    
    func generateNavigationUrl() -> URL {
        URL(string: ConstantsApi.server)!
    }
    
    private func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = ApiConstants.HttpMethod.get.rawValue
        request.setValue(ApiConstants.userAgent, forHTTPHeaderField: ApiConstants.userAgentKey)
        request.addValue(ApiConstants.defaultContentType, forHTTPHeaderField: ApiConstants.contentTypeKey)
        return request
    }
}
