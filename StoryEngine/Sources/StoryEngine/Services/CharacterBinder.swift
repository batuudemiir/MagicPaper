import Foundation
import CharacterEngine

/// The one place a `StoryCharacter` comes into existence.
///
/// `StoryCharacter`'s initializer is internal to this module and takes a
/// `ResolvedCharacter`, so every character in every story provably came through
/// the Character Engine's contract. Nothing else in the engine can mint one.
public struct CharacterBinder: Sendable {
    private let characterEngine: CharacterEngineContract

    public init(characterEngine: CharacterEngineContract) {
        self.characterEngine = characterEngine
    }

    public func bindCast(for request: StoryRequest) async throws -> [StoryCharacter] {
        do {
            let cast = try await characterEngine.resolveCast(for: request.cast)
            return cast.all.map(StoryCharacter.init(resolved:))
        } catch let error as CharacterEngineError {
            throw StoryEngineError.character(error)
        }
    }
}
