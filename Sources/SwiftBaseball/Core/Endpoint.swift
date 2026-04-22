import Foundation

struct Endpoint {
    static let defaultVersion = "v1"

    let path: String
    let queryItems: [URLQueryItem]
    /// API version segment for this endpoint. Most endpoints use `"v1"` — the
    /// live game feed uses `"v1.1"`. The concrete URL is built by swapping
    /// `v1` in the configured base URL for this version when they differ.
    let version: String

    init(path: String, queryItems: [URLQueryItem] = [], version: String = Endpoint.defaultVersion) {
        self.path = path
        self.queryItems = queryItems
        self.version = version
    }

    func adding(name: String, value: String?) -> Endpoint {
        guard let value else { return self }
        return Endpoint(
            path: path,
            queryItems: queryItems + [URLQueryItem(name: name, value: value)],
            version: version
        )
    }

    /// Replaces an existing query item or adds it if not present.
    func replacing(name: String, value: String) -> Endpoint {
        var items = queryItems.filter { $0.name != name }
        items.append(URLQueryItem(name: name, value: value))
        return Endpoint(path: path, queryItems: items, version: version)
    }

    func url(baseURL: URL) -> URL? {
        let versioned = applying(version: version, to: baseURL)
        guard var components = URLComponents(
            url: versioned.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else { return nil }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        return components.url
    }

    /// If `baseURL` ends with the default version segment (e.g. `/api/v1/`)
    /// and this endpoint wants a different version, swap the segment in place.
    /// Otherwise return `baseURL` unchanged.
    private func applying(version: String, to baseURL: URL) -> URL {
        guard version != Endpoint.defaultVersion else { return baseURL }
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return baseURL
        }
        let hadTrailingSlash = components.path.hasSuffix("/")
        var segments = components.path.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
        guard let lastIndex = segments.indices.last,
              segments[lastIndex] == Endpoint.defaultVersion
        else { return baseURL }
        segments[lastIndex] = version
        components.path = "/" + segments.joined(separator: "/") + (hadTrailingSlash ? "/" : "")
        return components.url ?? baseURL
    }
}
