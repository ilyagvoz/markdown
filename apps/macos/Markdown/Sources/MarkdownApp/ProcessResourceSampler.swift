import Darwin
import Foundation

struct ProcessResourceSnapshot: Equatable {
    let cpuPercent: Double
    let residentMemoryBytes: UInt64

    var displayText: String {
        "CPU \(Int(cpuPercent.rounded()))% · \(Self.formatMemory(residentMemoryBytes))"
    }

    private static func formatMemory(_ bytes: UInt64) -> String {
        let megabytes = Double(bytes) / 1_048_576
        if megabytes < 1_024 {
            return "\(Int(megabytes.rounded())) MB"
        }
        let gigabytes = megabytes / 1_024
        return String(format: "%.1f GB", gigabytes)
    }
}

final class ProcessResourceSampler {
    private var previousCPUTime: Double?
    private var previousWallTime: Date?

    func sample() -> ProcessResourceSnapshot {
        ProcessResourceSnapshot(
            cpuPercent: currentCPUPercent(),
            residentMemoryBytes: currentResidentMemory()
        )
    }

    private func currentResidentMemory() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), rebound, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }
        return UInt64(info.resident_size)
    }

    private func currentCPUPercent() -> Double {
        var usage = rusage()
        guard getrusage(RUSAGE_SELF, &usage) == 0 else { return 0 }

        let cpuTime = seconds(usage.ru_utime) + seconds(usage.ru_stime)
        let wallTime = Date()

        defer {
            previousCPUTime = cpuTime
            previousWallTime = wallTime
        }

        guard let previousCPUTime,
              let previousWallTime
        else {
            return 0
        }

        let cpuDelta = max(0, cpuTime - previousCPUTime)
        let wallDelta = max(0.001, wallTime.timeIntervalSince(previousWallTime))
        return min(999, cpuDelta / wallDelta * 100)
    }

    private func seconds(_ time: timeval) -> Double {
        Double(time.tv_sec) + Double(time.tv_usec) / 1_000_000
    }
}
