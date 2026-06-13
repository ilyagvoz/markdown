import AppKit

@MainActor
final class KeyboardShortcutMonitor {
    private var monitor: Any?

    func install(
        onBack: @escaping @MainActor () -> Void,
        onForward: @escaping @MainActor () -> Void,
        onPreviousFile: @escaping @MainActor () -> Void,
        onNextFile: @escaping @MainActor () -> Void,
        onToggleLeftPane: @escaping @MainActor () -> Void,
        onToggleRightPane: @escaping @MainActor () -> Void
    ) {
        guard monitor == nil else { return }

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard modifiers == .command else { return event }

            switch event.keyCode {
            case 33:
                onBack()
                return nil
            case 30:
                onForward()
                return nil
            case 126:
                onPreviousFile()
                return nil
            case 125:
                onNextFile()
                return nil
            case 123:
                onToggleLeftPane()
                return nil
            case 124:
                onToggleRightPane()
                return nil
            default:
                return event
            }
        }
    }

    func uninstall() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }
}
