import AppKit

@MainActor
final class IdleActivityMonitor {
    private var monitor: Any?

    func start(onActivity: @escaping @MainActor () -> Void) {
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
}
