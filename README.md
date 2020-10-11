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

ImpactMeterAdapter translates Impact crash reports into a form that conforms to `Meter.DiagnosticPayloadProtocol`, and delivers them via `MeterPayloadManager`. On platforms where `MXCrashDiagnostic` is supported, Impact will not be initialized. This gives you a way to transparently make use of MetricKit crash reporting when available, and Impact-based reporting when it is not.

Not that this conversion process is **lossy**. `MXCrashDiagnostic` does not support of the types of information that crash reporters typically capture. In particular, you loose access to `NSException` details, as well as thread/queue names.

## Suggestions or Feedback

We'd love to hear from you! Get in touch via [twitter](https://twitter.com/chimehq), an issue, or a pull request.

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.
