//
//  ImpactDiagnostic.swift
//  ImpactMeterAdapter
//
//  Created by Matt Massicotte on 2020-10-08.
//

import Foundation
import Meter

class ImpactDiagnosticPayload: DiagnosticPayloadProtocol {
    private let impactCrash: ImpactCrashDiagnostic

    init(log: ImpactLog) {
        self.impactCrash = ImpactCrashDiagnostic(log: log)
    }

    convenience init(contentsOf URL: URL) throws {
        let log = try ImpactLog(contentsOf: URL)

        self.init(log: log)
    }

    func jsonRepresentation() -> Data {
        let diagnostics: [CrashDiagnostic]?

        if impactCrash.containsCrashEvents {
            diagnostics = [impactCrash.asCrashDiagnostic]
        } else {
            diagnostics = nil
        }

        let payload = DiagnosticPayload(timeStampBegin: timeStampBegin,
                                        timeStampEnd: timeStampEnd,
                                        crashDiagnostics: diagnostics)
        
        return payload.jsonRepresentation()
    }

    var timeStampBegin: Date {
        return Date()
    }

    var timeStampEnd: Date {
        return Date()
    }

    var crashDiagnostics: [CrashDiagnosticProtocol]? {
        if impactCrash.containsCrashEvents {
            return [impactCrash]
        }

        return []
    }
}

class ImpactCrashDiagnostic: CrashDiagnosticProtocol {
    private let log: ImpactLog

    init(log: ImpactLog) {
        self.log = log
    }

    var containsCrashEvents: Bool {
        return terminationReason != "<unknown>"
    }

    var callStackTree: CallStackTreeProtocol {
        return internalCallStackTree
    }

    lazy var internalCallStackTree: CallStackTree = {
        let stacks = log.threads.map { callStack(for: $0, with: log.binaries) }

        return CallStackTree(callStacks: stacks, callStackPerThread: true)
    }()

    var terminationReason: String? {
        if let number = log.signal?.number {
            let hexFormatted = String(number, radix: 16)

            return "Namespace SIGNAL, Code 0x\(hexFormatted)"
        }

        return "<unknown>"
    }

    var virtualMemoryRegionInfo: String? {
        return nil
    }

    var exceptionType: NSNumber? {
        return nil
    }

    var exceptionCode: NSNumber? {
        return nil
    }

    var signal: NSNumber? {
        return log.signal?.number.map({ NSNumber(integerLiteral: $0) })
    }

    var applicationVersion: String {
        return log.application?.shortVersion ?? "<unknown>"
    }

    private var normalizedPlatform: String? {
        guard let platform = log.environment?.platform else {
            return nil
        }

        if platform == "iOS" {
            return "iPhone OS"
        } else {
            return platform
        }
    }

    private var osVersion: String? {
        guard
            let platform = normalizedPlatform,
            let version = log.environment?.osVersion,
            let build = log.environment?.osBuild
        else {
            return nil
        }

        return "\(platform) \(version) (\(build))"
    }

    lazy var internalMetaData: CrashMetaData = {
        return CrashMetaData(deviceType: log.environment?.model ?? "",
                             applicationBuildVersion: log.application?.version ?? "",
                             applicationVersion: applicationVersion,
                             osVersion: osVersion ?? "",
                             platformArchitecture: log.environment?.architecture ?? "",
                             regionFormat: "",
                             virtualMemoryRegionInfo: nil,
                             exceptionType: exceptionType?.intValue,
                             terminationReason: terminationReason,
                             exceptionCode: exceptionCode?.intValue,
                             signal: signal?.intValue)
    }()

    var metaData: MetaDataProtocol {
        return internalMetaData
    }

    lazy var asCrashDiagnostic: CrashDiagnostic = {
        return CrashDiagnostic(metaData: internalMetaData, callStackTree: internalCallStackTree)
    }()

    func jsonRepresentation() -> Data {
        return asCrashDiagnostic.jsonRepresentation()
    }

    private func callStack(for thread: ImpactThread, with binaries: [ImpactBinary]) -> CallStack {
        var currentFrame: Frame?

        for frame in thread.frames.reversed() {
            let binary = binaries.first(where: { $0.contains(frame: frame) })
            let offset = binary?.frameOffset(frame)
            let address = frame.ip ?? 0
            let subframes = currentFrame.flatMap({ [$0] }) ?? []

            currentFrame = Frame(binaryUUID: binary?.uuid,
                                 offsetIntoBinaryTextSegment: offset,
                                 sampleCount: 1,
                                 binaryName: binary?.name,
                                 address: address,
                                 subFrames: subframes)
        }

        let rootFrames = currentFrame.flatMap({ [$0] }) ?? []

        return CallStack(threadAttributed: thread.crashed, rootFrames: rootFrames)
    }
}
