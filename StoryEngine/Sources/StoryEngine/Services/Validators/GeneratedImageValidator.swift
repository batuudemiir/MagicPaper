import Foundation

/// Turns recorded image-validation verdicts into publication decisions.
///
/// Deterministic: the looking already happened in `ImageValidationService`, and
/// this only reads what it wrote. Keeping the judgement here means every reason
/// a book can be blocked lives in the same validator pipeline, and the same
/// verdict always produces the same outcome.
///
/// The rule that carries the weight is what happens when nobody looked. Under
/// `.required`, an unavailable provider blocks publication, because the
/// alternative is shipping an unexamined picture to a child while the system
/// reports success.
public struct GeneratedImageValidator: DeterministicValidator {
    public let id = ValidatorID.generatedImage
    public init() {}

    public func validate(_ context: ValidationContext) -> [ValidationIssue] {
        let mode = context.template.template.generationPolicy.imageValidationMode
        guard mode != .off else { return [] }

        var issues: [ValidationIssue] = []

        for scene in context.story.scenes {
            for asset in scene.visualAssets where asset.isReady {
                guard let record = asset.currentValidation else {
                    // Ready, but never looked at — and the record does not even
                    // say it was skipped.
                    issues.append(
                        issue(
                            "image_validation_missing",
                            mode == .required ? .error : .warning,
                            .visualAsset(asset.id),
                            "The illustration was produced but never checked."
                        )
                    )
                    continue
                }

                switch record.result {
                case .passed:
                    continue

                case .failed(let observations):
                    // A safety finding is an error whatever the mode: advisory
                    // means "do not block on quality", not "ship anything".
                    let hasSafetyFinding = observations.contains { $0.finding.isSafetyFinding }
                    let severity: ValidationSeverity = (mode == .required || hasSafetyFinding) ? .error : .warning
                    issues.append(
                        issue(
                            record.result.code,
                            severity,
                            .visualAsset(asset.id),
                            "The illustration failed checking: \(describe(observations))."
                        )
                    )

                case .uncertain(let reason, let observations):
                    // Under `.required`, "I cannot tell" is not good enough.
                    issues.append(
                        issue(
                            record.result.code,
                            mode == .required ? .error : .warning,
                            .visualAsset(asset.id),
                            observations.isEmpty
                                ? "Checking the illustration was inconclusive: \(reason)."
                                : "Checking the illustration was inconclusive (\(reason)): \(describe(observations))."
                        )
                    )

                case .providerUnavailable(let reason):
                    issues.append(
                        issue(
                            record.result.code,
                            mode == .required ? .error : .warning,
                            .visualAsset(asset.id),
                            "The illustration could not be checked: \(reason)."
                        )
                    )

                case .skipped(let reason):
                    issues.append(
                        issue(
                            record.result.code,
                            mode == .required ? .error : .info,
                            .visualAsset(asset.id),
                            "Checking the illustration was skipped: \(reason)."
                        )
                    )
                }
            }
        }

        return issues
    }

    private func describe(_ observations: [ImageValidationObservation]) -> String {
        observations
            .map { observation in
                observation.detail.isEmpty
                    ? observation.finding.rawValue
                    : "\(observation.finding.rawValue) (\(observation.detail))"
            }
            .joined(separator: ", ")
    }
}
