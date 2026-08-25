import Foundation

nonisolated struct URLPolicy: Equatable, Sendable {
    enum ValidationError: Error, Equatable, LocalizedError {
        case invalidAllowedHost(String)

        var errorDescription: String? {
            switch self {
            case let .invalidAllowedHost(host):
                "AllowedHosts contains an invalid host: \(host)"
            }
        }
    }

    let allowedHosts: [String]

    init(allowedHosts: [String]) throws {
        self.allowedHosts = try allowedHosts.map(Self.normalizedHost)
    }

    func allows(_ url: URL?) -> Bool {
        guard let url,
              url.scheme?.lowercased() == "https",
              let host = url.host?.lowercased()
        else {
            return false
        }

        return allowedHosts.contains { allowedHost in
            host == allowedHost || host.hasSuffix(".\(allowedHost)")
        }
    }

    private static func normalizedHost(_ value: String) throws -> String {
        let host = value.lowercased()
        let labels = host.split(separator: ".", omittingEmptySubsequences: false)
        let validCharacters = CharacterSet(
            charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-"
        )

        guard !host.isEmpty,
              host.count <= 253,
              labels.allSatisfy({ label in
                  !label.isEmpty &&
                      label.count <= 63 &&
                      label.first != "-" &&
                      label.last != "-" &&
                      label.unicodeScalars.allSatisfy(validCharacters.contains)
              })
        else {
            throw ValidationError.invalidAllowedHost(value)
        }

        return host
    }
}
