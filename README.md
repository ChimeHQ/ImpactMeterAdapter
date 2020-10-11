[![Github CI](https://github.com/ChimeHQ/ImpactMeterAdapter/workflows/CI/badge.svg)](https://github.com/ChimeHQ/ImpactMeterAdapter/actions)

# ImpactMeterAdapter

Convert [Impact](https://github.com/ChimeHQ/Impact) crash reports into a [Meter](https://github.com/ChimeHQ/Meter) diagnostic source.

## Integration

Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/ChimeHQ/ImpactMeterAdapter.git")
]
```

## What It Does

ImpactMeterAdapter gives you `MXCrashDiagnostic` payload when running on a supported platform/OS, and emulated payloads derived from Impact reports for backwards compatibility. When `MXCrashDiagnostic` is supported, Impact is not initialized. This gives you an easy way to interact with a consistent interface, as the (hopeful) migration towards `MXCrashDiagnostic` progresses.

ImpactMeterAdapter supports macOS 10.13+, iOS 12.0+, and tvOS 12.0+.

## Getting Started

```
import ImpactMeterAdapter

class ExampleSubscriber {
    init() {
        MeterPayloadManager.shared.add(self)

        // Configure Impact here, if needed

        ImpactMeterDiagnosticProvider.shared.start()
    }
}

extension ExampleSubscriber: MeterPayloadSubscriber {
    func didReceive(_ payloads: [DiagnosticPayloadProtocol]) {
        // Here you will receive MXCrashDiagnostics when supported, or
        // an equivalent Impact-based version otherwise.
    }
}
```

For actually transmitting data back to a server, check out [Wells](https://github.com/ChimeHQ/Wells).

## Suggestions or Feedback

We'd love to hear from you! Get in touch via [twitter](https://twitter.com/chimehq), an issue, or a pull request.

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.
