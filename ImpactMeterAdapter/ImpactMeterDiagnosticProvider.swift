//
//  ImpactMeterDiagnosticProvider.swift
//  ImpactMeterAdapter
//
//  Created by Matt Massicotte on 2020-10-07.
//

import Foundation
import Meter
import Impact
import os.log

public class ImpactMeterDiagnosticProvider {
    public static let shared = ImpactMeterDiagnosticProvider()

    public let reportDirectoryURL: URL
    public let identifier = UUID()
    public var reportingEnabled = true
    private let logger: OSLog

    private init(url: URL = ImpactMeterDiagnosticProvider.defaultDirectory) {
        self.logger = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "ImpactMeterDiagnosticProvider")
        self.reportDirectoryURL = url
    }

    private var processingDirectoryURL: URL {
        return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    }

    public func start() {
        createReportDirectoryIfNeeded()

        let existingURLs = existingLogURLs

        if reportingEnabled == false {
            os_log("disabled", log: self.logger, type: .info)

            deleteAllLogs(with: existingURLs)

            return
        }

        let idString = identifier.uuidString

        let logURL = reportDirectoryURL.appendingPathComponent(idString, isDirectory: false).appendingPathExtension("impactlog")

        ImpactMonitor.shared().start(with: logURL, identifier: identifier)

        reportExistingLogs(with: existingURLs)
    }

    private func createReportDirectoryIfNeeded() {
        let url = reportDirectoryURL

        if FileManager.default.fileExists(atPath: url.path, isDirectory: nil) {
            return
        }

        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        } catch {
            os_log("failed to create reporting directory: %{public}@ ", log: self.logger, type: .fault, String(describing: error))
        }
    }

    private func reportExistingLogs(with URLs: [URL]) {
        let payloads = URLs.compactMap({ translateLogToPayload(at: $0) })
        let reportablePayloads = payloads.filter({ isReportable($0) })

        if reportablePayloads.isEmpty {
            return
        }

        MeterPayloadManager.shared.deliver(reportablePayloads)
    }

    private func isReportable(_ payload: ImpactDiagnosticPayload) -> Bool {
        guard let diagnostics = payload.crashDiagnostics else {
            return false
        }

        return diagnostics.isEmpty == false
    }

    private func translateLogToPayload(at url: URL) -> ImpactDiagnosticPayload? {
        do {
            let destURL = processingDirectoryURL.appendingPathComponent(url.lastPathComponent)

            os_log("moving log for processing %{public}@ -> %{public}@", log: self.logger, type: .info, url.description, destURL.description)

            try FileManager.default.moveItem(at: url, to: destURL)

            return try ImpactDiagnosticPayload(contentsOf: url)
        } catch {
            os_log("failed to translate log: %{public}@ ", log: self.logger, type: .fault, String(describing: error))
        }

        return nil
    }
}

extension ImpactMeterDiagnosticProvider {
    private static var fallbackDirectory: URL {
        return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    }

    private static var bundleScopedCachesDirectory: URL? {
        guard let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }

        guard let bundleId = Bundle.main.bundleIdentifier else { return nil }

        return url.appendingPathComponent(bundleId)
    }

    public static var defaultDirectory: URL {
        let baseURL = bundleScopedCachesDirectory ?? fallbackDirectory

        return baseURL.appendingPathComponent("Impact")
    }
}


extension ImpactMeterDiagnosticProvider {
    public var existingLogURLs: [URL] {
        return contentsOfDirectory(at: reportDirectoryURL)
    }

    private func contentsOfDirectory(at url: URL) -> [URL] {
        do {
            return try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
        } catch {
            os_log("failed to get crash directory contents", log: self.logger, type: .error)
        }

        return []
    }

    private func deleteAllLogs(with urls: [URL]) {
        if urls.count > 0 {
            os_log("removing all logs", log: self.logger, type: .info)
        }

        for url in urls {
            removeLog(at: url)
        }
    }

    private func removeLog(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            os_log("failed to remove log at %{public}@ %{public}@", log: self.logger, type: .error, url.path, error.localizedDescription)
        }
    }
}
