"""Export all source pages, distinctly labeling successful vs blocked runtime books."""
from pathlib import Path
import hashlib,json,sys
ROOT=Path(__file__).resolve().parents[4];OUT=Path(__file__).resolve().parent
EVIDENCE=Path(sys.argv[1]) if len(sys.argv)>1 else OUT
sha=lambda b:hashlib.sha256(b).hexdigest()
raw=(ROOT/'Content/Pilots/five-friends-56-runtime-v4/payload.json').read_bytes();payload=json.loads(raw);digest=sha(raw)
fixtures=json.loads((EVIDENCE/'forced-books.json').read_text());sample=json.loads((EVIDENCE/'sampling.json').read_text());good={b['bookID']:b for b in fixtures}
assert len(good)==len(fixtures) and set(good).issubset({b['id'] for b in payload['books']})
books=[]
for b in payload['books']:
    composed=good.get(b['id']);pages=[]
    if composed:assert composed['sourceReference']['payloadSHA256']==digest and len(composed['pages'])==8
    for i,source in enumerate(b['pages']):
        rendered=composed['pages'][i] if composed else None
        if rendered:
            assert sha(rendered['text'].encode())==rendered['provenance']['renderedSHA256']
            assert rendered['provenance']['templateID']==source['templateID']
            assert rendered['provenance']['parentSHA256']==source['parentSHA256']
        pages.append(dict(pageNumber=source['number'],fullAuthoredText=source['parentText'],fullRenderedText=rendered['text'] if rendered else None,previousAuthoredPageText=b['pages'][i-1]['parentText'] if i else None,nextAuthoredPageText=b['pages'][i+1]['parentText'] if i<7 else None,sourceIdentity={k:source[k] for k in ['templateID','templateSHA256','parentSourceID','parentSHA256','parentPointer']},runtimeProvenance=rendered['provenance'] if rendered else None,typedTransition=rendered['transition'] if rendered else None,semantics=rendered['semantics'] if rendered else source['semantics'],authoredSemantics=source['semantics'],specificArtNeeds=rendered['artHandoff'] if rendered else source['artHandoff'],atomicActionMappingApproved=False,artApproved=False))
    books.append(dict(bookID=b['id'],structureID=b['structureID'],mode=b['mode'],companionID=b['companionID'],titleTemplate=b['titleTemplate'],runtimeStatus='successful-composed-fixture' if composed else 'blocked-authored-source-only',runtimeTitle=composed['title'] if composed else None,pages=pages))
report=dict(schemaVersion=1,payloadSHA256=digest,scope='90 source books; successful fixtures and blocked sources explicitly distinguished',sourceBooks=90,sourcePages=720,successfulComposedBooks=len(fixtures),blockedSourceBooks=90-len(fixtures),productionEnabled=False,artApproved=False,books=books)
coverage=dict(requests=sample['attempts'],successfulBooks=sample['successes'],failedRequests=sample['failures'],successfulPages=sample['successes']*8,booksWithArt=0,pagesWithArt=0,approvedP56Rules=0,retryCount=sample['retries'],textSelectionInfluencedByArt=False,artAcceptance='not-approved')
for name,value in [('art-handoff.json',report),('art-coverage.json',coverage)]: (OUT/name).write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:report[k] for k in ['sourceBooks','sourcePages','successfulComposedBooks','blockedSourceBooks']}))
