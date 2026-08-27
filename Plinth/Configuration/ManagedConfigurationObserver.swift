import Foundation

final nonisolated class ManagedConfigurationObserver: NSObject {
    private let defaults: UserDefaults
    private let onChange: @Sendable () -> Void

    init(
        defaults: UserDefaults,
        onChange: @escaping @Sendable () -> Void
    ) {
        self.defaults = defaults
        self.onChange = onChange
        super.init()

        for key in ManagedConfiguration.Key.allCases {
            defaults.addObserver(
                self,
                forKeyPath: key.rawValue,
                options: [],
                context: nil
            )
        }
    }

    deinit {
        for key in ManagedConfiguration.Key.allCases {
            defaults.removeObserver(self, forKeyPath: key.rawValue)
        }
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard let keyPath,
              ManagedConfiguration.Key(rawValue: keyPath) != nil
        else {
            super.observeValue(
                forKeyPath: keyPath,
                of: object,
                change: change,
                context: context
            )
            return
        }

        onChange()
    }
}
