import Foundation

struct Endpoint: Sendable {
    let path: String
    let queryItems: [URLQueryItem]

    init(path: String, queryItems: [URLQueryItem] = []) {
        self.path = path
        self.queryItems = queryItems
    }

    func adding(name: String, value: String?) -> Endpoint {
        guard let value else { return self }
        return Endpoint(path: path, queryItems: queryItems + [URLQueryItem(name: name, value: value)])
    }

    /// Replaces an existing query item or adds it if not present.
    func replacing(name: String, value: String) -> Endpoint {
        var items = queryItems.filter { $0.name != name }
        items.append(URLQueryItem(name: name, value: value))
        return Endpoint(path: path, queryItems: items)
    }

    func url(baseURL: URL) -> URL? {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else { return nil }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        return components.url
    }
}
