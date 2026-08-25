import Foundation

nonisolated enum ManagedConfigurationState: Equatable, Sendable {
    case disabled
    case enabled(ManagedConfiguration)
}

nonisolated struct ManagedConfiguration: Equatable, Sendable {
    enum ValidationError: Error, Equatable, LocalizedError {
        case missingStartURL
        case invalidStartURL
        case invalidAllowedHosts
        case invalidIdleResetSeconds
        case invalidEphemeralSession

        var errorDescription: String? {
            switch self {
            case .missingStartURL:
                "StartURL is required when Plinth is enabled."
            case .invalidStartURL:
                "StartURL must be an absolute HTTPS URL."
            case .invalidAllowedHosts:
                "AllowedHosts must contain valid host names."
            case .invalidIdleResetSeconds:
                "IdleResetSeconds must be a non-negative integer."
            case .invalidEphemeralSession:
                "EphemeralSession must be a Boolean."
            }
        }
    }

    let startURL: URL
    let urlPolicy: URLPolicy
    let idleResetSeconds: Int
    let ephemeralSession: Bool

    static func load(from defaults: UserDefaults) throws -> ManagedConfigurationState {
        guard defaults.object(forKey: "Enabled") as? Bool == true else {
            return .disabled
        }

        guard let startURLValue = defaults.object(forKey: "StartURL") as? String else {
            throw ValidationError.missingStartURL
        }
        guard let startURL = URL(string: startURLValue),
              startURL.scheme?.lowercased() == "https",
              startURL.host?.isEmpty == false
        else {
            throw ValidationError.invalidStartURL
        }

        let configuredHosts: [String]
        if let value = defaults.object(forKey: "AllowedHosts") {
            guard let hosts = value as? [String] else {
                throw ValidationError.invalidAllowedHosts
            }
            configuredHosts = hosts
        } else {
            configuredHosts = []
        }

        guard let startHost = startURL.host else {
            throw ValidationError.invalidStartURL
        }

        let urlPolicy: URLPolicy
        do {
            urlPolicy = try URLPolicy(
                allowedHosts: configuredHosts.isEmpty ? [startHost] : configuredHosts
            )
        } catch {
            throw ValidationError.invalidAllowedHosts
        }

        let idleResetSeconds: Int
        if let value = defaults.object(forKey: "IdleResetSeconds") {
            guard let number = value as? NSNumber,
                  CFGetTypeID(number) != CFBooleanGetTypeID(),
                  number.doubleValue.rounded() == number.doubleValue,
                  number.intValue >= 0
            else {
                throw ValidationError.invalidIdleResetSeconds
            }
            idleResetSeconds = number.intValue
        } else {
            idleResetSeconds = 0
        }

        let ephemeralSession: Bool
        if let value = defaults.object(forKey: "EphemeralSession") {
            guard let enabled = value as? Bool else {
                throw ValidationError.invalidEphemeralSession
            }
            ephemeralSession = enabled
        } else {
            ephemeralSession = true
        }

        return .enabled(
            ManagedConfiguration(
                startURL: startURL,
                urlPolicy: urlPolicy,
                idleResetSeconds: idleResetSeconds,
                ephemeralSession: ephemeralSession
            )
        )
    }
}
