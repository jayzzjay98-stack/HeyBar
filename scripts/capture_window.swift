import CoreGraphics
import Foundation

struct CaptureArguments {
    let owner: String
}

private func parseArguments() -> CaptureArguments? {
    var owner: String?

    var iterator = CommandLine.arguments.dropFirst().makeIterator()
    while let argument = iterator.next() {
        switch argument {
        case "--owner":
            owner = iterator.next()
        default:
            continue
        }
    }

    guard let owner else { return nil }
    return CaptureArguments(owner: owner)
}

private func largestWindowID(for owner: String) -> UInt32? {
    guard let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
        return nil
    }

    let windows = info.filter { window in
        guard let ownerName = window[kCGWindowOwnerName as String] as? String,
              let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
              let width = bounds["Width"],
              let height = bounds["Height"] else {
            return false
        }

        return ownerName == owner && width > 180 && height > 120
    }

    let sorted = windows.sorted { lhs, rhs in
        let lhsBounds = lhs[kCGWindowBounds as String] as? [String: CGFloat] ?? [:]
        let rhsBounds = rhs[kCGWindowBounds as String] as? [String: CGFloat] ?? [:]
        let lhsArea = (lhsBounds["Width"] ?? 0) * (lhsBounds["Height"] ?? 0)
        let rhsArea = (rhsBounds["Width"] ?? 0) * (rhsBounds["Height"] ?? 0)
        return lhsArea > rhsArea
    }

    return sorted.first?[kCGWindowNumber as String] as? UInt32
}

guard let arguments = parseArguments() else {
    fputs("usage: swift capture_window.swift --owner <OwnerName>\n", stderr)
    exit(1)
}

guard let windowID = largestWindowID(for: arguments.owner) else {
    fputs("no matching on-screen windows found for \(arguments.owner)\n", stderr)
    exit(2)
}

print(windowID)
