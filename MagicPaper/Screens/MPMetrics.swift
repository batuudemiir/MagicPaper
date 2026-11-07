import MetricKit
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "MPMetrics")

/// Kararlılık ve performans ölçümü (Faz 0, `docs/STARTUP_PLANI.md`). Apple'ın
/// birinci taraf MetricKit'i: üçüncü taraf yok, sunucuya bir şey gitmez, kullanıcı
/// verisi taşımaz. Yalnızca sayıları günlüğe yazar; ayrıntılar Xcode Organizer'da.
final class MPMetrics: NSObject, MXMetricManagerSubscriber {
    static let shared = MPMetrics()

    func start() {
        MXMetricManager.shared.add(self)
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            logger.error("""
                Tanılama: \(payload.crashDiagnostics?.count ?? 0) çökme, \
                \(payload.hangDiagnostics?.count ?? 0) takılma
                """)
        }
    }
}
