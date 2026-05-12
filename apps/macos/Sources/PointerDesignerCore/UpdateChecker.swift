import Foundation

public struct AppUpdateInfo: Equatable, Sendable {
    public let tagName: String
    public let releaseURL: URL
    public let publishedAt: Date?

    public init(tagName: String, releaseURL: URL, publishedAt: Date?) {
        self.tagName = tagName
        self.releaseURL = releaseURL
        self.publishedAt = publishedAt
    }
}

public enum UpdateCheckResult: Equatable, Sendable {
    case upToDate(AppUpdateInfo)
    case updateAvailable(AppUpdateInfo)
}

public enum UpdateCheckError: Error, Equatable, LocalizedError, Sendable {
    case internetAccessNotAllowed
    case invalidReleaseURL
    case invalidResponse
    case network(String)

    public var errorDescription: String? {
        switch self {
        case .internetAccessNotAllowed:
            return "Internet access for update checks is disabled in Cursor Designer settings."
        case .invalidReleaseURL:
            return "Cursor Designer could not build the release metadata URL."
        case .invalidResponse:
            return "Cursor Designer could not read release metadata."
        case .network(let message):
            return "Update check failed: \(message)"
        }
    }
}

public final class UpdateChecker {
    public static let shared = UpdateChecker()

    private let repository = "rogu3bear/macOS-pointer-designer"
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func checkLatestRelease(
        allowsInternetAccess: Bool,
        currentVersion: String,
        completion: @escaping (Result<UpdateCheckResult, UpdateCheckError>) -> Void
    ) {
        guard allowsInternetAccess else {
            completion(.failure(.internetAccessNotAllowed))
            return
        }

        guard let url = URL(string: "https://api.github.com/repos/\(repository)/releases/latest") else {
            completion(.failure(.invalidReleaseURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("CursorDesigner/\(currentVersion)", forHTTPHeaderField: "User-Agent")

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.network(error.localizedDescription)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode),
                  let data = data else {
                completion(.failure(.invalidResponse))
                return
            }

            do {
                let release = try JSONDecoder.githubReleaseDecoder.decode(GitHubRelease.self, from: data)
                guard let releaseURL = URL(string: release.htmlURL) else {
                    completion(.failure(.invalidResponse))
                    return
                }

                let info = AppUpdateInfo(
                    tagName: release.tagName,
                    releaseURL: releaseURL,
                    publishedAt: release.publishedAt
                )

                if Self.isRelease(release.tagName, newerThan: currentVersion) {
                    completion(.success(.updateAvailable(info)))
                } else {
                    completion(.success(.upToDate(info)))
                }
            } catch {
                completion(.failure(.invalidResponse))
            }
        }.resume()
    }

    public static func isRelease(_ tagName: String, newerThan currentVersion: String) -> Bool {
        let releaseParts = versionParts(from: tagName)
        let currentParts = versionParts(from: currentVersion)

        for index in 0..<max(releaseParts.count, currentParts.count) {
            let release = index < releaseParts.count ? releaseParts[index] : 0
            let current = index < currentParts.count ? currentParts[index] : 0
            if release != current {
                return release > current
            }
        }

        return false
    }

    private static func versionParts(from value: String) -> [Int] {
        let normalized = value.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
        return normalized
            .split(separator: ".")
            .map { part in
                let numericPrefix = part.prefix { $0.isNumber }
                return Int(numericPrefix) ?? 0
            }
    }
}

private struct GitHubRelease: Decodable {
    let tagName: String
    let htmlURL: String
    let publishedAt: Date?

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case publishedAt = "published_at"
    }
}

private extension JSONDecoder {
    static var githubReleaseDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
