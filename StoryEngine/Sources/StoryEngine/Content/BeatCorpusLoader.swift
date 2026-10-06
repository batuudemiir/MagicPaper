import Foundation

/// Reads the per-beat prose corpus.
///
/// The corpus is authored one file per beat — `beat_notice_anomaly.json`,
/// `beat_warm_close.json` — rather than as one document of templates. That is
/// the right shape for writing: an author works on one beat at a time, across
/// every story that uses it, and a file per beat is what makes a review a
/// readable diff instead of a search through a thousand-line array.
///
/// The engine's unit is still a template, so each file becomes one:
/// `realizesBeat` is the file's beat, and the variants are its lines.
public struct BeatCorpusLoader: Sendable {

    /// A word budget, as the corpus declares it.
    public struct WordBand: Sendable, Hashable {
        public let lower: Int
        public let upper: Int
        public func contains(_ count: Int) -> Bool { (lower...upper).contains(count) }

        /// Parses the leading "10-16 words" from a band description.
        ///
        /// The rest of the line is the author's note about *why*, which is worth
        /// keeping in the file and not worth parsing.
        static func parse(_ text: String) -> WordBand? {
            guard let match = text.range(of: #"^\s*(\d+)\s*[-–]\s*(\d+)"#, options: .regularExpression)
            else { return nil }
            let numbers = text[match].split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
            guard numbers.count == 2 else { return nil }
            return WordBand(lower: numbers[0], upper: numbers[1])
        }
    }

    /// Bir beat'in bir yaş bandındaki hâli.
    public struct BandedBeat: Hashable, Sendable {
        public let beat: StoryBeat
        public let band: AgeBand?
        public init(_ beat: StoryBeat, _ band: AgeBand?) {
            self.beat = beat
            self.band = band
        }
    }

    /// One authored beat file.
    private struct BeatFile: Decodable {
        let beat: StoryBeat
        let variants: [CatalogVariant]
        /// Per-beat word bands. **Not the same for every beat**: `meet_companion`
        /// is a long partner, so `companion_offers` is banded 8-14 rather than
        /// the usual 10-16, to keep the shared page inside one budget. Assuming
        /// a single paired band would pass lines that put the page out of it.
        let lengthClasses: [String: String]?
        /// Dosyanın en üstünde baştan beri yazılıydı ve baştan beri
        /// OKUNMUYORDU. Tek bant varken zararsızdı; ikinci bant yazıldığı an
        /// 3-4 cümleleri 5-6 masallarına karışırdı.
        let ageBand: AgeBand?
        /// Declared in the file and **not used**: `StoryBeat` is the single
        /// source for what a beat requires and produces. Decoded only so the
        /// checker below can say when the two have drifted apart.
        let produces: [NarrativeStateKey]?
        let requires: [NarrativeStateKey]?
        /// Lines written only for a series episode (FAZ 13). They load into
        /// `seriesTemplates` and never join a standalone story's pool.
        let series: Bool?
    }

    /// What a load found, including what it could not use.
    public struct Report: Sendable {
        public let templates: [CatalogTemplate]
        /// Episode-only lines (FAZ 13), kept apart from `templates`.
        public let seriesTemplates: [CatalogTemplate]
        /// The word bands the series files declare, keyed like `bands`. Apart,
        /// because a series file may budget the same beat differently.
        public let seriesBands: [BandedBeat: [VariantLengthClass: WordBand]]
        public let files: [String]
        /// The word band each beat declares, per length class.
        /// Beat VE banda göre. Yalnızca beat'e göre anahtarlamak, 3-4 için
        /// yazılmış dokuz kelimelik bir `commit` satırını 5-6'nın 18-38
        /// bandıyla ölçüyordu — doğru satır, yanlış cetvel.
        public let bands: [BandedBeat: [VariantLengthClass: WordBand]]
        /// Files that were present and could not be read, with the reason.
        public let skipped: [String]
        /// Beat files whose declared requires/produces disagree with the
        /// engine's. Reported rather than obeyed — two sources for one fact
        /// drift, and the engine is the one the validator uses.
        public let drifted: [String]

        init(
            templates: [CatalogTemplate],
            seriesTemplates: [CatalogTemplate] = [],
            files: [String],
            bands: [BandedBeat: [VariantLengthClass: WordBand]],
            seriesBands: [BandedBeat: [VariantLengthClass: WordBand]] = [:],
            skipped: [String],
            drifted: [String]
        ) {
            self.templates = templates
            self.seriesTemplates = seriesTemplates
            self.seriesBands = seriesBands
            self.files = files
            self.bands = bands
            self.skipped = skipped
            self.drifted = drifted
        }

        public var isEmpty: Bool { templates.isEmpty }
    }

    /// A stable id for the template a beat file becomes.
    /// Şablon kimliği beat VE banttan üretilir.
    ///
    /// Yalnızca beat'ten üretmek tek bant varken yetiyordu. İkinci bant gelince
    /// aynı beat için iki şablon aynı id'yi alır — ve `duplicate_id` bütünlük
    /// hatası, 3-4 korpusunun neden çalışmadığını açıklayan en son yer olurdu.
    static func templateID(for beat: StoryBeat, band: AgeBand?) -> ContentID {
        guard let band else { return ContentID("corpus_" + beat.rawValue) }
        return ContentID("corpus_\(band.description)_" + beat.rawValue)
    }

    /// A series file's template id: apart from the standalone one, so the two
    /// templates for one beat and band never collide.
    static func seriesTemplateID(for beat: StoryBeat, band: AgeBand?) -> ContentID {
        ContentID("series_\(band?.description ?? "any")_" + beat.rawValue)
    }

    public init() {}

    /// Loads every `beat_*.json` in the package bundle.
    ///
    /// A missing corpus is not an error: the library ships its own templates,
    /// and the corpus is additional prose layered on top.
    public func load() -> Report { load(in: .module) }

    public func load(in bundle: Bundle) -> Report {
        guard let urls = bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) else {
            return Report(templates: [], files: [], bands: [:], skipped: [], drifted: [])
        }
        return load(urls: urls.filter { $0.lastPathComponent.hasPrefix("beat_") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent })
    }

    func load(urls: [URL]) -> Report {
        load(files: urls.map { ($0.lastPathComponent, try? Data(contentsOf: $0)) })
    }

    /// The corpus from files already in hand — a content package (FAZ 15)
    /// carries the same beat files the bundle does. A `nil` body is a file that
    /// could not be read, and is skipped the same way.
    func load(files sources: [(name: String, data: Data?)]) -> Report {
        var templates: [CatalogTemplate] = []
        var seriesTemplates: [CatalogTemplate] = []
        var files: [String] = []
        var bands: [BandedBeat: [VariantLengthClass: WordBand]] = [:]
        var seriesBands: [BandedBeat: [VariantLengthClass: WordBand]] = [:]
        var skipped: [String] = []
        var drifted: [String] = []

        for (name, data) in sources {
            guard let data else {
                skipped.append("\(name): unreadable")
                continue
            }
            let file: BeatFile
            do {
                file = try JSONDecoder().decode(BeatFile.self, from: data)
            } catch {
                skipped.append("\(name): \(error)")
                continue
            }
            guard !file.variants.isEmpty else {
                skipped.append("\(name): no variants")
                continue
            }

            if let declared = file.produces, Set(declared) != Set(file.beat.produces) {
                drifted.append("\(name): declares produces \(declared.map(\.rawValue).sorted()), "
                               + "engine says \(file.beat.produces.map(\.rawValue).sorted())")
            }

            let isSeries = file.series == true
            if let declared = file.lengthClasses {
                let parsed: [VariantLengthClass: WordBand] = declared.reduce(into: [:]) { result, entry in
                    guard let kind = VariantLengthClass(rawValue: entry.key),
                          let band = WordBand.parse(entry.value) else { return }
                    result[kind] = band
                }
                if isSeries {
                    seriesBands[BandedBeat(file.beat, file.ageBand)] = parsed
                } else {
                    bands[BandedBeat(file.beat, file.ageBand)] = parsed
                }
            }

            let template = CatalogTemplate(
                id: isSeries
                    ? Self.seriesTemplateID(for: file.beat, band: file.ageBand)
                    : Self.templateID(for: file.beat, band: file.ageBand),
                role: Self.role(for: file.beat),
                realizesBeat: file.beat,
                compatibleThemes: [],
                variants: file.variants,
                ageBand: file.ageBand
            )
            if isSeries { seriesTemplates.append(template) } else { templates.append(template) }
            files.append(name)
        }

        return Report(templates: templates, seriesTemplates: seriesTemplates, files: files,
                      bands: bands, seriesBands: seriesBands, skipped: skipped, drifted: drifted)
    }

    /// The page role a beat usually fills.
    ///
    /// Layout intent only — role has not driven text selection since the beat
    /// model landed, and the corpus does not declare one. A beat that can sit
    /// on more than one kind of page gets the one it most often occupies.
    static func role(for beat: StoryBeat) -> PageRole {
        switch beat {
        case .establishOrdinary, .noticeAnomaly, .revisit: return .hook
        case .approach, .examine: return .discovery
        case .meetCompanion, .companionOffers, .receiveAppeal: return .companion
        case .commit, .formBelief, .beliefFails, .obstacleRaises, .hesitate, .takeCharge:
            return .problem
        case .firstAttempt, .smallStep, .tend, .prepare: return .attempt
        case .insight, .cooperativeEffort, .askForHelp, .persist, .patientWait,
             .findOwnCourage, .revealTruth, .speakFor, .giveUpSomething,
             .retrace, .exchangeViews, .letGo:
            return .challenge
        case .succeed, .restore: return .resolution
        case .selfRecognize, .warmClose, .carryForward: return .emotionalEnding
        }
    }
}
