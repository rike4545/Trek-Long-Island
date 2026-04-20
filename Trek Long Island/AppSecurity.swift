// Copyright Bryan Carroll. All rights reserved.
import Foundation
import UIKit
import Darwin
import MachO

enum AppSecurity {
    static func enforceIfNeeded() {
        #if DEBUG
        return
        #else
        if isCompromised() {
            kill(getpid(), SIGKILL)
            exit(173)
        }
        #endif
    }

    private static func isCompromised() -> Bool {
        return isDebuggerAttached()
            || hasInjectedLibraries()
            || hasHookingLibraries()
            || isJailbroken()
    }

    private static func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]

        let result = mib.withUnsafeMutableBufferPointer { mibPtr in
            sysctl(mibPtr.baseAddress, u_int(mibPtr.count), &info, &size, nil, 0)
        }
        return result == 0 && ((info.kp_proc.p_flag & P_TRACED) != 0)
    }

    private static func hasInjectedLibraries() -> Bool {
        guard let value = getenv("DYLD_INSERT_LIBRARIES") else { return false }
        return String(cString: value).isEmpty == false
    }

    private static func hasHookingLibraries() -> Bool {
        let markers = ["frida", "substrate", "substitute", "cydia", "libhooker"]
        let imageCount = _dyld_image_count()
        for i in 0 ..< imageCount {
            guard let name = _dyld_get_image_name(i) else { continue }
            let lower = String(cString: name).lowercased()
            if markers.contains(where: { lower.contains($0) }) {
                return true
            }
        }
        return false
    }

    private static func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        let suspiciousPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/"
        ]

        if suspiciousPaths.contains(where: { FileManager.default.fileExists(atPath: $0) }) {
            return true
        }

        let canWriteOutsideSandbox = (try? "tli".write(
            toFile: "/private/tli_jb_test.txt",
            atomically: true,
            encoding: .utf8)
        ) != nil

        if canWriteOutsideSandbox {
            try? FileManager.default.removeItem(atPath: "/private/tli_jb_test.txt")
            return true
        }

        return false
        #endif
    }
}
