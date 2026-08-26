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
        case invalidDisplayScheduleEnabled
        case invalidDisplaySchedule

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
            case .invalidDisplayScheduleEnabled:
                "DisplayScheduleEnabled must be a Boolean."
            case .invalidDisplaySchedule:
                "Display scheduling requires different HH:mm on/off times and one or more valid day names."
            }
        }
    }

    let startURL: URL
    let urlPolicy: URLPolicy
    let idleResetSeconds: Int
    let ephemeralSession: Bool
    let displaySchedule: DisplaySchedule?

    static func administratorEscapeCode(from defaults: UserDefaults) -> String? {
        guard let code = defaults.object(forKey: "EscapeCode") as? String,
              !code.isEmpty
        else {
            return nil
        }
        return code
    }

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

        let displaySchedule: DisplaySchedule?
        if let value = defaults.object(forKey: "DisplayScheduleEnabled") {
            guard let enabled = value as? Bool else {
                throw ValidationError.invalidDisplayScheduleEnabled
            }

            if enabled {
                guard let onTime = defaults.object(forKey: "DisplayOnTime") as? String,
                      let offTime = defaults.object(forKey: "DisplayOffTime") as? String
                else {
                    throw ValidationError.invalidDisplaySchedule
                }

                let dayNames: [String]?
                if let value = defaults.object(forKey: "DisplayDays") {
                    guard let days = value as? [String] else {
                        throw ValidationError.invalidDisplaySchedule
                    }
                    dayNames = days
                } else {
                    dayNames = nil
                }

                do {
                    displaySchedule = try DisplaySchedule(
                        onTime: onTime,
                        offTime: offTime,
                        dayNames: dayNames
                    )
                } catch {
                    throw ValidationError.invalidDisplaySchedule
                }
            } else {
                displaySchedule = nil
            }
        } else {
            displaySchedule = nil
        }

        return .enabled(
            ManagedConfiguration(
                startURL: startURL,
                urlPolicy: urlPolicy,
                idleResetSeconds: idleResetSeconds,
                ephemeralSession: ephemeralSession,
                displaySchedule: displaySchedule
            )
        )
    }
}
