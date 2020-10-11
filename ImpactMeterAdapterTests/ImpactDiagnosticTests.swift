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
        let url = try XCTUnwrap(crashLogURL(named: "signal_crash"))
        let payload = try ImpactDiagnosticPayload(contentsOf: url)

        XCTAssertEqual(payload.crashDiagnostics?.count, 1)

        let diagnostic = try XCTUnwrap(payload.crashDiagnostics?[0])

        XCTAssertEqual(diagnostic.applicationVersion, "1.0")
        XCTAssertEqual(diagnostic.terminationReason, "Namespace SIGNAL, Code 0x6")
        XCTAssertNil(diagnostic.virtualMemoryRegionInfo)
        XCTAssertEqual(diagnostic.signal, 6)

        let tree = diagnostic.callStackTree

        XCTAssertEqual(tree.callStacks.count, 6)

        XCTAssertFalse(tree.callStacks[1].threadAttributed)

        let crashedStack = tree.callStacks[0]

        XCTAssertTrue(crashedStack.threadAttributed)

        let frames = crashedStack.frames
        XCTAssertEqual(frames.count, 18)

        XCTAssertEqual(frames[0].sampleCount, 1)
        XCTAssertEqual(frames[0].binaryUUID, UUID(uuidString: "FE013604-05CD-3D10-99AD-E9BD1C0945AA"))
        XCTAssertEqual(frames[0].binaryName, "libsystem_kernel.dylib")
        XCTAssertEqual(frames[0].address, 0x1d465b5d0)
        XCTAssertEqual(frames[0].offsetIntoBinaryTextSegment, 0x95D0)

        XCTAssertEqual(frames[17].sampleCount, 1)
        XCTAssertEqual(frames[17].binaryUUID, UUID(uuidString: "F32B02E1-CA2F-3BEA-9A8E-F21B4ACB6095"))
        XCTAssertEqual(frames[17].binaryName, "libdyld.dylib")
        XCTAssertEqual(frames[17].address, 0x1d44ea844)
        XCTAssertEqual(frames[17].offsetIntoBinaryTextSegment, 0x16844)
    }

    func testParsingImpactJSONOuput() throws {
        let url = try XCTUnwrap(crashLogURL(named: "signal_crash"))
        let impactPayload = try ImpactDiagnosticPayload(contentsOf: url)
        let jsonData = impactPayload.JSONRepresentation()

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
