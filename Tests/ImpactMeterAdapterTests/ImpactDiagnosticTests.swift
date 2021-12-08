//
//  ImpactDiagnosticTests.swift
//  ImpactMeterAdapterTests
//
//  Created by Matt Massicotte on 2020-10-08.
//

import XCTest
import Meter
@testable import ImpactMeterAdapter

class ImpactDiagnosticTests: XCTestCase {
    private func crashLogURL(named name: String) -> URL? {
        return Bundle(for: ImpactDiagnosticTests.self).url(forResource: name, withExtension: "impactlog")
    }

    func testDiagnosticPayloadTransformation() throws {
        let url = try XCTUnwrap(crashLogURL(named: "macos_signal_crash"))
        let payload = try ImpactDiagnosticPayload(contentsOf: url)

        XCTAssertEqual(payload.crashDiagnostics?.count, 1)

        let diagnostic = try XCTUnwrap(payload.crashDiagnostics?[0])

        XCTAssertEqual(diagnostic.metaData.applicationBuildVersion, "1")
        XCTAssertEqual(diagnostic.metaData.deviceType, "MacBookPro15,2")
        XCTAssertEqual(diagnostic.metaData.osVersion, "macOS 10.15.7 (19H2)")
        XCTAssertEqual(diagnostic.metaData.platformArchitecture, "x86_64")
        XCTAssertEqual(diagnostic.metaData.regionFormat, "CA")
        XCTAssertNil(diagnostic.virtualMemoryRegionInfo)
        XCTAssertEqual(diagnostic.applicationVersion, "1.0")
        XCTAssertEqual(diagnostic.terminationReason, "Namespace SIGNAL, Code 0x6")
        XCTAssertEqual(diagnostic.signal, 6)
//        XCTAssertEqual(diagnostic.exceptionCode, 0)
//        XCTAssertEqual(diagnostic.exceptionType, 1)

        let tree = diagnostic.callStackTree

        XCTAssertEqual(tree.callStacks.count, 6)

        XCTAssertTrue(tree.callStacks[1].threadAttributed == false)

        let crashedStack = tree.callStacks[0]

        XCTAssertTrue(crashedStack.threadAttributed == true)

        let frames = crashedStack.frames
        XCTAssertEqual(frames.count, 18)

        XCTAssertEqual(frames[0].sampleCount, 1)
        XCTAssertEqual(frames[0].binaryUUID, UUID(uuidString: "A576A1CF-7726-3146-B04B-A26E1CDB9757"))
        XCTAssertEqual(frames[0].binaryName, "libsystem_kernel.dylib")
        XCTAssertEqual(frames[0].address, 0x7fff7153333a)
        XCTAssertEqual(frames[0].offsetIntoBinaryTextSegment, 0x733A)

        XCTAssertEqual(frames[17].sampleCount, 1)
        XCTAssertEqual(frames[17].binaryUUID, UUID(uuidString: "789A18C2-8AC7-3C88-813D-CD674376585D"))
        XCTAssertEqual(frames[17].binaryName, "libdyld.dylib")
        XCTAssertEqual(frames[17].address, 0x7fff713ebcc9)
        XCTAssertEqual(frames[17].offsetIntoBinaryTextSegment, 0x1ACC9)
    }

    func testParsingImpactJSONOuput() throws {
        let url = try XCTUnwrap(crashLogURL(named: "macos_signal_crash"))
        let impactPayload = try ImpactDiagnosticPayload(contentsOf: url)
        let jsonData = impactPayload.jsonRepresentation()

        let payload = try DiagnosticPayload.from(data: jsonData)

        XCTAssertEqual(payload.crashDiagnostics?.count, 1)

        let diagnostic = try XCTUnwrap(payload.crashDiagnostics?.first)

        XCTAssertEqual(diagnostic.applicationVersion, "1.0")
        XCTAssertEqual(diagnostic.terminationReason, "Namespace SIGNAL, Code 0x6")
        XCTAssertNil(diagnostic.virtualMemoryRegionInfo)
        XCTAssertEqual(diagnostic.signal, 6)

        Swift.print("output: \(String(data: jsonData, encoding: .utf8)!)")
    }
}
