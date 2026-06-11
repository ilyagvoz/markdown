import Foundation

@MainActor
final class DirectoryWatcher {
    private var sources: [DispatchSourceFileSystemObject] = []
    private var fileDescriptors: [CInt] = []
    private var debounceTask: Task<Void, Never>?

    func watch(urls: [URL], onChange: @escaping @MainActor () -> Void) {
        stop()

        let uniquePaths = Array(Set(urls.map { $0.standardizedFileURL.path })).sorted()
        for path in uniquePaths {
            let descriptor = open(path, O_EVTONLY)
            guard descriptor >= 0 else { continue }
            fileDescriptors.append(descriptor)

            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: descriptor,
                eventMask: [.write, .extend, .attrib, .delete, .rename, .revoke],
                queue: DispatchQueue.main
            )

            source.setEventHandler { [weak self] in
                self?.debounceTask?.cancel()
                self?.debounceTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(220))
                    guard !Task.isCancelled else { return }
                    onChange()
                }
            }

            source.setCancelHandler { [descriptor] in
                close(descriptor)
            }

            sources.append(source)
            source.resume()
        }
    }

    func stop() {
        debounceTask?.cancel()
        debounceTask = nil
        sources.forEach { $0.cancel() }
        sources = []
        fileDescriptors = []
    }
}
