//
//  ImpactLogTests.swift
//  ImpactMeterAdapterTests
//
//  Created by Matt Massicotte on 2020-10-07.
//

import XCTest
@testable import ImpactMeterAdapter

class ImpactLogTests: XCTestCase {
    private func crashLogURL(named name: String) -> URL? {
        return Bundle(for: ImpactLogTests.self).url(forResource: name, withExtension: "impactlog")
    }

    func testNonCrashLog() throws {
        let url = try XCTUnwrap(crashLogURL(named: "noncrash"))

        let log = try ImpactLog(contentsOf: url)

        XCTAssertEqual(log.application?.identifier, "MyCoolApp")
        XCTAssertEqual(log.application?.organizationIdentifier, "MyCoolOrg")
        XCTAssertEqual(log.application?.version, "25")
        XCTAssertEqual(log.application?.shortVersion, "5.0")

        XCTAssertEqual(log.binaries.count, 387)

        XCTAssertEqual(log.binaries[0].path, "/Applications/Chime.app/Contents/MacOS/Chime")
        XCTAssertNotNil(log.binaries[0].uuid)
        XCTAssertEqual(log.binaries[0].uuid, UUID(uuidString: "6B61AD3B-8FB8-38EE-A78A-F3BD65F29461"))
        XCTAssertEqual(log.binaries[0].size, 0x2ac000)
        XCTAssertEqual(log.binaries[0].address, 0x10bff7000)
    }

    func testSignalCrashLog() throws {
        let url = try XCTUnwrap(crashLogURL(named: "signal_crash"))

        let log = try ImpactLog(contentsOf: url)

        XCTAssertEqual(log.application?.identifier, "com.chimehq.ImpactTestMac")
        XCTAssertEqual(log.application?.shortVersion, "1.0")

        XCTAssertEqual(log.signal?.number, 0x6)
        XCTAssertEqual(log.signal?.code, 0x0)

        XCTAssertEqual(log.threads.count, 6)
        XCTAssertTrue(log.threads[0].crashed)
        XCTAssertEqual(log.threads[0].frames.count, 18)
        XCTAssertEqual(log.threads[0].frames[0].ip, 0x1d465b5d0)
        XCTAssertEqual(log.threads[0].frames[0].sp, 0x16faf6d30)
        XCTAssertEqual(log.threads[0].frames[0].fp, 0x16faf6d50)

        XCTAssertFalse(log.threads[1].crashed)
        XCTAssertEqual(log.threads[1].frames.count, 1)
        XCTAssertEqual(log.threads[1].frames[0].ip, 0x1d46555d8)
        XCTAssertEqual(log.threads[1].frames[0].sp, 0x16fb7efb0)
        XCTAssertEqual(log.threads[1].frames[0].fp, 0x16fb7efe0)
    }
}
