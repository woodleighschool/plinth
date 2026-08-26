import AppKit

@MainActor
final class LocalEventMonitor {
    private static let administratorEscapeModifiers: NSEvent.ModifierFlags = [
        .command,
        .control,
        .option,
    ]

    private var monitor: Any?

    func start(
        onActivity: @escaping @MainActor () -> Void,
        onAdministratorEscape: @escaping @MainActor () -> Bool
    ) {
        guard monitor == nil else {
            return
        }

        monitor = NSEvent.addLocalMonitorForEvents(
            matching: [
                .keyDown,
                .leftMouseDown,
                .rightMouseDown,
                .otherMouseDown,
                .mouseMoved,
                .leftMouseDragged,
                .rightMouseDragged,
                .otherMouseDragged,
                .scrollWheel,
                .gesture,
                .magnify,
                .rotate,
                .swipe,
            ]
        ) { event in
            onActivity()
            if event.type == .keyDown,
               Self.isAdministratorEscape(
                   characters: event.charactersIgnoringModifiers,
                   modifiers: event.modifierFlags
               ),
               onAdministratorEscape()
            {
                return nil
            }
            return event
        }
    }

    func stop() {
        guard let monitor else {
            return
        }

        NSEvent.removeMonitor(monitor)
        self.monitor = nil
    }

    static func isAdministratorEscape(
        characters: String?,
        modifiers: NSEvent.ModifierFlags
    ) -> Bool {
        guard characters?.lowercased() == "e" else {
            return false
        }

        let relevantModifiers = modifiers.intersection([
            .command,
            .control,
            .option,
            .shift,
        ])
        return relevantModifiers == administratorEscapeModifiers
    }
}
