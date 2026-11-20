import SwiftUI
import UIKit
import XCTest
@testable import MagicPaper

@MainActor
final class ReaderThemeTests: XCTestCase {
    func testDayPaperIsWhiteInBothSystemAppearances() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let rgb = components(MP.ReadTheme.light.paper, style: style)
            XCTAssertEqual(rgb[0], 1, accuracy: 0.001)
            XCTAssertEqual(rgb[1], 1, accuracy: 0.001)
            XCTAssertEqual(rgb[2], 1, accuracy: 0.001)
        }
    }

    func testOptionalPapersRemainDistinctFromDayPaper() {
        for theme in MP.ReadTheme.allCases where theme != .light {
            XCTAssertNotEqual(components(theme.paper), components(MP.ReadTheme.light.paper), theme.label)
        }
    }

    func testStoryTextRetainsReadableContrastOnEveryPaper() {
        for theme in MP.ReadTheme.allCases {
            let foreground = luminance(components(theme.body))
            let background = luminance(components(theme.paper))
            let ratio = (max(foreground, background) + 0.05) / (min(foreground, background) + 0.05)
            XCTAssertGreaterThanOrEqual(ratio, 4.5, theme.label)
        }
    }

    private func components(_ color: Color, style: UIUserInterfaceStyle = .light) -> [Double] {
        let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        XCTAssertTrue(resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        return [Double(red), Double(green), Double(blue)]
    }

    private func luminance(_ rgb: [Double]) -> Double {
        let linear = rgb.map { $0 <= 0.04045 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4) }
        return linear[0] * 0.2126 + linear[1] * 0.7152 + linear[2] * 0.0722
    }
}
