# Research sources — terms review

2026-10-08. Each source was checked for licence, terms of use and robots.txt before any
code was written for it. Decision D7 (architecture §13). Re-check a source's terms if its
adapter starts failing or a year has passed.

| Source | Licence of the books | Automated access | Decision | Route |
|---|---|---|---|---|
| **Project Gutenberg** | Public domain in the USA (per-book RDF says so) | robots.txt disallows only `/ebooks/search`; Gutenberg publishes a catalog feed and per-book files for programs | ✅ adapter | `discover --source gutenberg`, `ingest gutenberg <id>` |
| **Internet Archive** | Varies per item; we accept only editions published ≤ 1930 (US public domain in 2026) outside lending collections | Documented APIs (`advancedsearch`, `metadata`, downloads). robots.txt disallows only `/control/`, `/report/`. Terms: access is for scholarship and research, do not burden servers, use must be non-infringing, cite the Archive in publications | ✅ adapter | `discover --source ia`, `ingest ia <identifier>`, `images` |
| **Book Dash** | CC BY 4.0, "no restriction … as long as they acknowledge Book Dash and the original creators" | robots.txt allows everything; the web reader shows page images | ✅ adapter (images + analyst transcription) | `discover --source bookdash`, `ingest bookdash <slug>` (twice) |
| **African Storybook** | CC BY 4.0; some stories add a non-commercial condition | robots.txt allows everything, but the reader serves story content only through its app mechanics (session/app endpoints). Working around that would be reverse-engineering | ⚠️ no adapter — read in a browser like any visitor, transcribe, `ingest file` | manual |
| **StoryWeaver** (Pratham Books) | Stories mostly CC BY 4.0 (check each story) | Terms limit use of the site and its software to personal use "and as allowed by the licence"; no stated programmatic access | ⚠️ no adapter — per-story manual route; ask StoryWeaver about research access if we need volume | manual |
| **Global Digital Library** | Open licences | Site is a JS app; no current public API found | ⏸ not pursued | — |
| **gutendex.com** | (mirror of Gutenberg metadata) | robots.txt disallows `/books/` for every agent | ❌ not used | — |

## What the gates enforce

- **Gutenberg:** fetch only when the RDF rights statement is exactly "Public domain in the USA."
- **Internet Archive:** refuse when the item is dark, access-restricted, in `inlibrary`,
  `printdisabled`, `lendinglibrary` or `browserlending`, has no publication year, or was published
  after the US public-domain cutoff (current year − 96). An uploader's licence claim is recorded,
  never relied on. Picture leaves are fetched one by one, only when the analyst asks (`images`).
- **Book Dash:** attribution string built from the four credited creatives, as Book Dash asks.
  Text is the analyst's transcription of page images and is labelled `analyst_transcription`.
- **All:** host allow-list (redirects to other hosts refused), robots.txt honoured and a fetch is
  refused if robots.txt cannot be read, ≥ 1.5 s between requests, an honest User-Agent, verified TLS.

## Evidence differences to keep in mind

| Source | Page boundaries | Pictures | Text | Era |
|---|---|---|---|---|
| Gutenberg | reconstructed (no page-turn claims) | none (markers only) | edition plain text | ≤ 1930 |
| Internet Archive | original scan | yes, per leaf | OCR (expect errors) | ≤ 1930 |
| Book Dash | publisher layout | yes, every page | analyst transcription | 2014-today |

Old public-domain books and new open-licence books are different populations. Reports keep them
apart; a claim resting on only one of them says so.

## Manual route (African Storybook, StoryWeaver, any licensed text)

1. Open the story in a browser as a normal reader; confirm its licence on the story page.
2. Write a page file (`=== page N ===`, text, `[illustration: …]`, `[no text]`).
3. `book-agent ingest file <file> --rights open_license --license "CC BY 4.0" --attribution "<as the
   platform asks>" --boundary publisher_layout --text-origin analyst_transcription …`
