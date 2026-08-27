import Foundation
@testable import Plinth
import Testing

struct ManagedConfigurationObserverTests {
    @Test func reportsChangesToEveryManagedConfigurationKey() async throws {
        let suiteName = "ManagedConfigurationObserverTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        await confirmation(
            expectedCount: ManagedConfiguration.Key.allCases.count
        ) { changed in
            let observer = ManagedConfigurationObserver(defaults: defaults) {
                changed()
            }

            for key in ManagedConfiguration.Key.allCases {
                defaults.set(UUID().uuidString, forKey: key.rawValue)
            }

            withExtendedLifetime(observer) {}
        }
    }
}
