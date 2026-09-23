import Foundation

nonisolated struct NetworkParticipant: Hashable, Sendable {
    enum Identity: Hashable, Sendable {
        case executable(path: String)
        case application(bundleIdentifier: String)
    }

    enum ValidationError: Error, LocalizedError {
        case invalidList
        case invalidEntry(index: Int, reason: String)

        var errorDescription: String? {
            switch self {
            case .invalidList:
                "NetworkParticipants must be an array of dictionaries."
            case let .invalidEntry(index, reason):
                "NetworkParticipants entry \(index + 1): \(reason)"
            }
        }
    }

    let identity: Identity
    let teamIdentifier: String?
    let isRequired: Bool

    static func load(from value: Any?) throws -> [NetworkParticipant] {
        guard let value else { return [] }
        guard let entries = value as? [[String: Any]] else {
            throw ValidationError.invalidList
        }

        var identities: Set<Identity> = []
        return try entries.enumerated().map { index, entry in
            func invalid(_ reason: String) -> ValidationError {
                .invalidEntry(index: index, reason: reason)
            }

            let keys: Set = ["ExecutablePath", "BundleIdentifier", "TeamIdentifier", "Required"]
            guard Set(entry.keys).isSubset(of: keys) else {
                throw invalid("Use ExecutablePath or BundleIdentifier, with optional TeamIdentifier and Required.")
            }

            let identity: Identity
            switch (entry["ExecutablePath"], entry["BundleIdentifier"]) {
            case let (path as String, nil):
                let components = path.split(separator: "/", omittingEmptySubsequences: false).dropFirst()
                guard path.hasPrefix("/"),
                      !components.isEmpty,
                      components.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }),
                      path.rangeOfCharacter(from: .controlCharacters) == nil,
                      path.rangeOfCharacter(from: CharacterSet(charactersIn: "*?[]")) == nil
                else {
                    throw invalid("ExecutablePath must be an absolute file path without wildcards or relative components.")
                }
                identity = .executable(path: path)
            case let (nil, bundleIdentifier as String):
                let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-")
                guard !bundleIdentifier.isEmpty,
                      bundleIdentifier.rangeOfCharacter(from: allowed.inverted) == nil,
                      bundleIdentifier.split(separator: ".", omittingEmptySubsequences: false).allSatisfy({ !$0.isEmpty })
                else {
                    throw invalid("BundleIdentifier must be an exact bundle identifier.")
                }
                identity = .application(bundleIdentifier: bundleIdentifier)
            default:
                throw invalid("Specify exactly one of ExecutablePath or BundleIdentifier as a string.")
            }

            let teamIdentifier: String?
            if let value = entry["TeamIdentifier"] {
                let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
                guard let team = value as? String,
                      team.count == 10,
                      team.rangeOfCharacter(from: allowed.inverted) == nil
                else {
                    throw invalid("TeamIdentifier must be a ten-character signing team identifier, or omitted.")
                }
                teamIdentifier = team
            } else {
                teamIdentifier = nil
            }

            let isRequired: Bool
            if let value = entry["Required"] {
                guard let number = value as? NSNumber,
                      CFGetTypeID(number) == CFBooleanGetTypeID()
                else {
                    throw invalid("Required must be a Boolean.")
                }
                isRequired = number.boolValue
            } else {
                isRequired = false
            }

            guard identities.insert(identity).inserted else {
                throw invalid("Each executable path or bundle identifier must appear only once.")
            }
            return NetworkParticipant(identity: identity, teamIdentifier: teamIdentifier, isRequired: isRequired)
        }
    }
}
