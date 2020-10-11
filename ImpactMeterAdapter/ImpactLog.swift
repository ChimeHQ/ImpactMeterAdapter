//
//  ImpactLog.swift
//  ImpactMeterAdapter
//
//  Created by Matt Massicotte on 2020-10-07.
//

import Foundation

private extension String {
    func asBase64EncodedString() -> String? {
        Data(base64Encoded: self).flatMap({ String(data: $0, encoding: .utf8) })
    }
}

/// Host Application Details
///
/// example:
/// `[Application] id: TXlDb29sQXBw, org_id: TXlDb29sT3Jn, version: MjU=, short_version: NS4w`
public struct ImpactApplication {
    static let prefix = "[Application] "

    public var identifier: String?
    public var organizationIdentifier: String?
    public var version: String?
    public var shortVersion: String?

    public init?(with line: Substring) {
        guard let entry = ImpactLog.entryDictionary(from: line, with: ImpactApplication.prefix) else { return nil }

        self.identifier = entry["id"].flatMap({ $0.asBase64EncodedString() })
        self.organizationIdentifier = entry["org_id"].flatMap({ $0.asBase64EncodedString() })
        self.version = entry["version"].flatMap({ $0.asBase64EncodedString() })
        self.shortVersion = entry["short_version"].flatMap({ $0.asBase64EncodedString() })
    }
}

extension UUID {
    init?(plainString string: String) {
        guard string.count == 32 else { return nil }

        var adjusted = string

        // 8 - 4 - 4 - 4
        // 1082F1ED-F524-4832-BD1B-3D4F1166539C
        let idx4 = adjusted.index(adjusted.startIndex, offsetBy: 8 + 4 + 4 + 4)

        adjusted.insert("-", at: idx4)

        let idx3 = adjusted.index(adjusted.startIndex, offsetBy: 8 + 4 + 4)

        adjusted.insert("-", at: idx3)

        let idx2 = adjusted.index(adjusted.startIndex, offsetBy: 8 + 4)

        adjusted.insert("-", at: idx2)

        let idx1 = adjusted.index(adjusted.startIndex, offsetBy: 8)

        adjusted.insert("-", at: idx1)

        self.init(uuidString: adjusted.uppercased())
    }
}

extension Int {
    init?(hexString string: String) {
        guard string.count >= 3 else { return nil }

        let hexNumericOnlyString = string.dropFirst(2)

        self.init(hexNumericOnlyString, radix: 16)
    }
}

/// Binary Image Details
///
/// example:
/// `[Binary:Load] path: /System/Library/Frameworks/AppKit.framework/Versions/C/AppKit, address: 0x7fff345ab000, size: 0xdc1000, slide: 0xa22d000, uuid: a64d10a6fe1739ce93926615be54e10e`
public struct ImpactBinary {
    static let loadPrefix = "[Binary:Load] "

    public var path: String?
    public var address: Int?
    public var size: Int?
    public var uuid: UUID?

    public init?(with line: Substring) {
        guard let entry = ImpactLog.entryDictionary(from: line, with: ImpactBinary.loadPrefix) else { return nil }

        self.path = entry["path"]
        self.uuid = entry["uuid"].flatMap({ UUID(plainString: $0) })
        self.size = entry["size"].flatMap({ Int(hexString: $0) })
        self.address = entry["address"].flatMap({ Int(hexString: $0) })
    }

    public func contains(frame: ImpactFrame) -> Bool {
        return frameOffset(frame) != nil
    }

    public var name: String? {
        return path?.components(separatedBy: "/").last
    }

    public var endAddress: Int? {
        guard
            let size = size,
            let address = address
        else {
            return nil
        }

        return address + size
    }

    public func frameOffset(_ frame: ImpactFrame) -> Int? {
        guard
            let address = address,
            let endAddress = endAddress,
            let ipAddress = frame.ip
        else {
            return nil
        }

        guard address <= ipAddress && endAddress > ipAddress else { return nil }

        return ipAddress - address
    }
}

/// Signal Details
///
/// example:
/// `[Signal] signal: 0x6, code: 0x0, address: 0x1d465b5d0, errno: 0x0`
public struct ImpactSignal {
    static let prefix = "[Signal] "

    public var number: Int?
    public var code: Int?

    public init?(with line: Substring) {
        guard let entry = ImpactLog.entryDictionary(from: line, with: ImpactSignal.prefix) else { return nil }

        self.number = entry["signal"].flatMap({ Int(hexString: $0) })
        self.code = entry["code"].flatMap({ Int(hexString: $0) })
    }
}

public struct ImpactThreadState {
    static let prefix = "[Thread:State] "
    static let crashPrefix = "[Thread:Crashed]"

    public var registers: [String: String]

    public init?(with line: Substring) {
        guard let entry = ImpactLog.entryDictionary(from: line, with: ImpactThreadState.prefix) else { return nil }

        self.registers = entry
    }
}

public struct ImpactFrame {
    static let prefix = "[Thread:Frame] "

    public var ip: Int?
    public var fp: Int?
    public var sp: Int?

    public init?(with line: Substring) {
        guard let entry = ImpactLog.entryDictionary(from: line, with: ImpactFrame.prefix) else { return nil }

        self.ip = entry["ip"].flatMap({ Int(hexString: $0) })
        self.fp = entry["fp"].flatMap({ Int(hexString: $0) })
        self.sp = entry["sp"].flatMap({ Int(hexString: $0) })
    }
}

public struct ImpactThread {
    public var state: ImpactThreadState?
    public var frames: [ImpactFrame]
    public var crashed: Bool

    init() {
        self.state = nil
        self.frames = []
        self.crashed = false
    }
}

private extension Array where Element == Substring {
    mutating func removeFirstIfMatches(_ key: String) -> Substring? {
        if let value = first, value.hasPrefix(key) {
            removeFirst()

            return value
        }

        return nil
    }
}

public struct ImpactLog {
    public var application: ImpactApplication?
    public var binaries: [ImpactBinary]
    public var signal: ImpactSignal?
    public var threads: [ImpactThread]

    public init(contentsOf URL: URL) throws {
        let contents = try String(contentsOf: URL)
        var lines = contents.split(separator: "\n")

        if let line = lines.removeFirstIfMatches(ImpactApplication.prefix) {
            self.application = ImpactApplication(with: line)
        }

        var parsedBinaries = [ImpactBinary]()
        var parsedThreads = [ImpactThread]()
        var currentThread: ImpactThread?

        while lines.count > 0 {
            if let line = lines.removeFirstIfMatches(ImpactBinary.loadPrefix) {
                if let binary = ImpactBinary(with: line) {
                    parsedBinaries.append(binary)
                }
            } else if let line = lines.removeFirstIfMatches(ImpactSignal.prefix) {
                self.signal = ImpactSignal(with: line)
            } else if let line = lines.removeFirstIfMatches(ImpactThreadState.prefix) {
                if let thread = currentThread {
                    parsedThreads.append(thread)
                }

                currentThread = ImpactThread()

                currentThread?.state = ImpactThreadState(with: line)
            } else if let _ = lines.removeFirstIfMatches(ImpactThreadState.crashPrefix) {
                currentThread?.crashed = true
            } else if let line = lines.removeFirstIfMatches(ImpactFrame.prefix) {
                if let frame = ImpactFrame(with: line) {
                    currentThread?.frames.append(frame)
                }
            } else {
                lines.removeFirst()
            }
        }

        if let thread = currentThread {
            parsedThreads.append(thread)
        }

        self.binaries = parsedBinaries
        self.threads = parsedThreads
    }

    public func lookupBinary(for frame: ImpactFrame) -> ImpactBinary? {
        return binaries.first(where: { $0.contains(frame: frame) })
    }

    public static func entryDictionary(from string: Substring, with key: String) -> [String: String]? {
        guard string.hasPrefix(key) else { return nil }

        let valuesString = string.suffix(string.count - key.count)
        let components = valuesString.components(separatedBy: ", ")
        let valuePairs = components.map({ $0.components(separatedBy: ": ") })

        var dict = [String: String]()

        for pair in valuePairs {
            guard pair.count == 2 else { continue }

            dict[pair[0]] = pair[1]
        }

        return dict
    }
}
