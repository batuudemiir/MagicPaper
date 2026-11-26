import StoryEngine

/// App persistence uses precisely the engine's lossless source wire envelope.
/// Keep one representation across origin, series plan, and account sync.
typealias StoredContentSource = ContentSourceMetadata
