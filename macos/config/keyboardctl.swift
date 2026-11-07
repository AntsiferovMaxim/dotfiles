import Foundation
import Carbon

enum KeyboardConfig {
    static let required = [
        "com.apple.keylayout.ABC",
        "com.apple.keylayout.Ukrainian-PC"
    ]
}

func property(
    _ source: TISInputSource,
    _ key: CFString
) -> String? {
    guard let pointer = TISGetInputSourceProperty(
        source,
        key
    ) else {
        return nil
    }

    return Unmanaged<AnyObject>
        .fromOpaque(pointer)
        .takeUnretainedValue() as? String
}

func allSources() -> [TISInputSource] {
    guard let result = TISCreateInputSourceList(
        nil,
        true
    ) else {
        return []
    }

    return result.takeRetainedValue()
        as NSArray as? [TISInputSource] ?? []
}

func sourceID(_ source: TISInputSource) -> String {
    property(source, kTISPropertyInputSourceID) ?? ""
}

func isKeyboardLayout(_ source: TISInputSource) -> Bool {
    property(source, kTISPropertyInputSourceType)
        == (kTISTypeKeyboardLayout as String)
}

func isEnabled(_ source: TISInputSource) -> Bool {
    guard let pointer = TISGetInputSourceProperty(
        source,
        kTISPropertyInputSourceIsEnabled
    ) else {
        return false
    }

    return Unmanaged<AnyObject>
        .fromOpaque(pointer)
        .takeUnretainedValue() as? Bool ?? false
}

func listSources(onlyEnabled: Bool = false) {
    for source in allSources() where isKeyboardLayout(source) {
        let enabled = isEnabled(source)

        if onlyEnabled && !enabled {
            continue
        }

        let name = property(
            source,
            kTISPropertyLocalizedName
        ) ?? "Unknown"

        let marker = enabled ? "[x]" : "[ ]"

        print("\(marker) \(name)")
        print("    \(sourceID(source))")
    }
}

func check(
    _ status: OSStatus,
    _ operation: String
) {
    guard status == noErr else {
        fputs(
            "Failed: \(operation), OSStatus \(status)\n",
            stderr
        )
        exit(1)
    }
}

func apply(dryRun: Bool) {
    let sources = allSources().filter(isKeyboardLayout)

    let byID = Dictionary(
        sources.map { (sourceID($0), $0) },
        uniquingKeysWith: { first, _ in first }
    )

    // Verify both layouts exist before changing anything.
    for id in KeyboardConfig.required {
        guard byID[id] != nil else {
            fputs("Missing input source: \(id)\n", stderr)
            exit(1)
        }
    }

    print(dryRun ? "Preview:" : "Applying configuration:")

    // Enable required layouts first.
    for id in KeyboardConfig.required {
        guard let source = byID[id] else {
            continue
        }

        if !isEnabled(source) {
            print("+ Enable \(id)")

            if !dryRun {
                check(
                    TISEnableInputSource(source),
                    "enable \(id)"
                )
            }
        }
    }

    // Select ABC before disabling other layouts.
    if let abc = byID[KeyboardConfig.required[0]] {
        print("-> Select ABC")

        if !dryRun {
            check(
                TISSelectInputSource(abc),
                "select ABC"
            )
        }
    }

    // Disable all other keyboard layouts.
    for source in sources {
        let id = sourceID(source)

        guard !KeyboardConfig.required.contains(id),
              isEnabled(source) else {
            continue
        }

        print("- Disable \(id)")

        if !dryRun {
            check(
                TISDisableInputSource(source),
                "disable \(id)"
            )
        }
    }

    if !dryRun {
        print("\nResult:")
        listSources(onlyEnabled: true)
    }
}

let arguments = Array(CommandLine.arguments.dropFirst())
let command = arguments.first ?? "status"
let dryRun = arguments.contains("--dry-run")

switch command {
case "list":
    listSources()

case "status":
    listSources(onlyEnabled: true)

case "apply":
    apply(dryRun: dryRun)

default:
    print("""
    Usage:
      keyboardctl list
      keyboardctl status
      keyboardctl apply --dry-run
      keyboardctl apply
    """)
    exit(1)
}
