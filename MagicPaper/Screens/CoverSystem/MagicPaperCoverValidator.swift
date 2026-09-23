import Foundation
import CoreGraphics

/// Validates cover configurations using only hard constraints.
struct CoverCompositionValidator {
    
    /// Validates the given configuration against 10 specific rules.
    /// - Parameter configuration: The cover configuration to validate.
    /// - Returns: A validation result containing an isValid boolean and any violations.
    func validate(_ configuration: MagicPaperCoverConfiguration) -> CoverValidationResult {
        var violations: [CoverValidationViolation] = []
        let tiles = configuration.tiles
        
        // Rule 4 & 5: Tile counts
        if tiles.count < 5 { violations.append(.tooFewTiles) }
        if tiles.count > 10 { violations.append(.tooManyTiles) }
        
        // Rule 2 & 3: Colors
        let distinctColors = Set(tiles.map { $0.colorToken })
        if tiles.count >= 3 && distinctColors.count < 3 {
            violations.append(.tooFewColors)
        }
        if distinctColors.count > 5 {
            violations.append(.tooManyColors)
        }
        
        // Rule 10: Valid geometry
        var hasInvalidGeometry = false
        for tile in tiles {
            if tile.width <= 0 || tile.height <= 0 {
                hasInvalidGeometry = true
                break
            }
        }
        if hasInvalidGeometry {
            violations.append(.invalidGeometry)
        }
        
        // Rule 6: Visual anchor
        if !tiles.isEmpty && !tiles.contains(where: { $0.width >= 0.28 }) {
            violations.append(.noVisualAnchor)
        }
        
        let titleAreaRect = CGRect(x: CoverConstants.titleSafeArea.x,
                                   y: CoverConstants.titleSafeArea.y,
                                   width: CoverConstants.titleSafeArea.width,
                                   height: CoverConstants.titleSafeArea.height)
        let titleAreaSize = titleAreaRect.width * titleAreaRect.height
        var totalTitleObscuredArea: CGFloat = 0
        
        var hasOutOfBounds = false
        var hasExcessiveOverlap = false
        
        for i in 0..<tiles.count {
            let tile = tiles[i]
            let tileRect = CGRect(x: tile.x, y: tile.y, width: tile.width, height: tile.height)
            let tileArea = tileRect.width * tileRect.height
            guard tileArea > 0 else { continue }
            
            // Rule 1: Title area obstruction
            let intersection = titleAreaRect.intersection(tileRect)
            if !intersection.isNull {
                totalTitleObscuredArea += (intersection.width * intersection.height)
            }
            
            // Rule 8: Tile out of bounds (max 60% outside)
            let coverBounds = CGRect(x: 0, y: 0, width: 1, height: 1)
            let boundsIntersection = coverBounds.intersection(tileRect)
            let insideArea = boundsIntersection.isNull ? 0 : (boundsIntersection.width * boundsIntersection.height)
            let outsideArea = tileArea - insideArea
            if (outsideArea / tileArea) > 0.60 {
                hasOutOfBounds = true
            }
            
            // Rule 7: Excessive overlap (max 45% of smaller tile)
            for j in (i + 1)..<tiles.count {
                let otherTile = tiles[j]
                let otherRect = CGRect(x: otherTile.x, y: otherTile.y, width: otherTile.width, height: otherTile.height)
                let otherArea = otherRect.width * otherRect.height
                guard otherArea > 0 else { continue }
                
                let tileIntersection = tileRect.intersection(otherRect)
                if !tileIntersection.isNull {
                    let overlapArea = tileIntersection.width * tileIntersection.height
                    let smallerArea = min(tileArea, otherArea)
                    if (overlapArea / smallerArea) > 0.45 {
                        hasExcessiveOverlap = true
                    }
                }
            }
        }
        
        if totalTitleObscuredArea / titleAreaSize > 0.30 {
            violations.append(.titleAreaObstructed)
        }
        if hasOutOfBounds {
            violations.append(.tileOutOfBounds)
        }
        if hasExcessiveOverlap {
            violations.append(.excessiveOverlap)
        }
        
        // Rule 9: Signature collides with title
        if let signature = configuration.signature, signature.type != .none {
            let sigPoint = CGPoint(x: signature.x, y: signature.y)
            // Giving the signature a small conceptual bound for collision testing
            let sigRect = CGRect(x: sigPoint.x - 0.02, y: sigPoint.y - 0.02, width: 0.04, height: 0.04)
            if !titleAreaRect.intersection(sigRect).isNull {
                violations.append(.signatureCollidesWithTitle)
            }
        }
        
        return CoverValidationResult(isValid: violations.isEmpty, violations: violations)
    }
}
