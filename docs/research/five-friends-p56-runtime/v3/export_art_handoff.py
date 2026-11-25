"""Export evidence from actual Swift-composed fixtures and first-attempt report.
No asset is assigned or generated; absence of reviewed P56 rules is explicit.
"""
from pathlib import Path
import hashlib
import json
import sys

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
EVIDENCE = Path(sys.argv[1]) if len(sys.argv) > 1 else OUT

def sha(data):
    return hashlib.sha256(data).hexdigest()

def read(path):
    return json.loads(path.read_text())

payload_bytes = (ROOT / 'Content/Pilots/five-friends-56-runtime-v3/payload.json').read_bytes()
payload = json.loads(payload_bytes)
digest = sha(payload_bytes)
books = read(EVIDENCE / 'forced-books.json')
sampling = read(EVIDENCE / 'sampling.json')
assert len(books) == 90 and len(sampling['attemptRecords']) == sampling['attempts']
assert sampling['successes'] + sampling['failures'] == sampling['attempts']
source_pages = {page['templateID']: page for book in payload['books'] for page in book['pages']}
assert len(source_pages) == 720
exported = []
for book in books:
    assert book['sourceReference']['payloadSHA256'] == digest
    assert len(book['pages']) == 8
    pages = []
    for index, page in enumerate(book['pages']):
        part = page['provenance']
        source = source_pages[part['templateID']]
        assert sha(page['text'].encode()) == part['renderedSHA256']
        assert source['templateSHA256'] == part['templateSHA256']
        assert source['parentSHA256'] == part['parentSHA256']
        assert page['artApproved'] is False
        pages.append({
            'pageNumber': page['number'],
            'fullRenderedText': page['text'],
            'previousPageText': book['pages'][index-1]['text'] if index else None,
            'nextPageText': book['pages'][index+1]['text'] if index+1 < len(book['pages']) else None,
            'settingID': page['settingID'],
            'orderedComposingParts': [dict(part, templateText=source['templateText'], parentAuthoredText=source['parentText'])],
            'semantics': page['semantics'],
            'typedTransition': page['transition'],
            'specificArtNeeds': page['artHandoff'],
            'authoredSemanticsForSourceInspectionOnly': page['authoredSemantics'],
            'authoredArtHandoffForSourceInspectionOnly': page.get('authoredArtHandoff'),
            'artDecision': {'status':'no-reviewed-p56-rule', 'assetID':None, 'approved':False},
            'atomicActionMappingApproved': False,
        })
    exported.append({
        'bookID':book['bookID'], 'structureID':book['structureID'], 'mechanism':book['mechanism'],
        'mode':book['mode'], 'title':book['title'], 'sourceReference':book['sourceReference'],
        'worldID':book['worldID'], 'companion':book['companion'],
        'child':{'id':book['childID'], 'name':book['childName'], 'identityReference':book.get('characterIdentityReference'),
                 'syntheticFixture':True, 'appearanceInvented':False},
        'pages':pages,
    })

coverage = {
    'requests':sampling['attempts'], 'successfulBooks':sampling['successes'],
    'failedRequests':sampling['failures'],
    'zeroArtBooks':sampling['successes'], 'requestsWithoutBoundArtIncludingFailures':sampling['attempts'],
    'booksWithArt':0, 'pagesWithArt':0, 'successfulPages':sampling['successes']*8,
    'positionCounts':{'opening':0,'middle':0,'ending':0}, 'repeatedAssets':0,
    'approvedP56Rules':0,
    'denialReasonCounts':{'no-reviewed-p56-rule':sampling['successes']*8},
    'measurementMethod':'Every successful sampled draft has artApproved=false and no asset field; there is no P56 rule catalog. Production legacy binders were not run against incompatible P56 types.',
    'retryCount':sampling['retries'], 'textSelectionInfluencedByArt':False,
    'artAcceptance':'not-approved',
}
summary = {
    'schemaVersion':1, 'payloadSHA256':digest, 'productionEnabled':False,
    'scope':'90 forced book fixtures; separate from 1500 first-attempt sampling denominator',
    'artCoverage':coverage,
    'sourceIDsAreDerivativeRuntimeIDs':True,
    'warning':'Full-page contextual actions and typed causal trace are evidence for review, not independently approved atomic art annotations.',
    'books':exported,
}
OUT.mkdir(parents=True, exist_ok=True)
(OUT/'art-handoff.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
(OUT/'art-coverage.json').write_text(json.dumps(coverage,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'books':len(exported),'pages':sum(len(b['pages']) for b in exported),'sourcePayloadSHA256':digest,'artCoverage':coverage},ensure_ascii=False))
