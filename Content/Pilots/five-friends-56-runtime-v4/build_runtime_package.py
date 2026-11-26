#!/usr/bin/env python3
"""Build an immutable v4 candidate from approved text plus separately read annotations.
Never edits v1/v2, approved input, active pins, or app resources.
"""
from pathlib import Path
import copy, hashlib, importlib.util, json, re
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
CORPUS=HERE.parent/'five-friends-56-voice-v4'
REVIEW=ROOT/'docs/research/five-friends-p56-runtime/v4'
CORPUS_ID=CORPUS.name

def sha(value): return hashlib.sha256(value.encode() if isinstance(value,str) else value).hexdigest()
def serialized(value): return json.dumps(value,ensure_ascii=False,indent=2)+'\n'
def write(path,value):
    path.parent.mkdir(parents=True,exist_ok=True)
    data=serialized(value);path.write_text(data,encoding='utf-8');return data

def template(text):
    result=re.sub(r"(?<![\w])Deniz(?:[’'](in|e|i|de|den))?(?![\w’'])",lambda m:'{{child.name}}'+("'"+m[1] if m[1] else ''),text)
    if 'Deniz' in result: raise ValueError('Unmapped child name: '+text)
    return result

def main():
    old_bytes=(HERE.parent/'five-friends-56-runtime-v3/payload.json').read_bytes()
    assert sha(old_bytes)=='855870c8462f167b4031058897c2ddfc8c5f513802ad057758c86e3ff5316c3c', 'Pinned v3 bytes changed'
    old=json.loads(old_bytes)
    approved={};inputs=[]
    for path in sorted((CORPUS/'input').glob('*.json')):
        raw=path.read_bytes();document=json.loads(raw);inputs.append(dict(file=str(path.relative_to(CORPUS)),sha256=sha(raw)))
        for entry in document['books']:
            key=entry['sourceBookID'];assert key not in approved and len(entry['pages'])==8
            approved[key]=entry
    assert set(approved)=={b['id'] for b in old['books']} and len(inputs)==15
    semantic=json.loads((REVIEW/'semantic-review.json').read_text())
    safety=json.loads((REVIEW/'safety-review-content.json').read_text())
    # Reviews use explicit bookID/pages; source hashes are bound only here.
    annotations={b['bookID']:b for b in semantic['books']}
    safety_by={b['bookID']:b for b in safety['books']}
    assert set(annotations)==set(approved)==set(safety_by)
    sources=[];books=[];lineages=[];evidence=[];manifest=[];safety_books=[]
    old_lineages={l['bookID']:l for l in old['bookLineages']}
    for base in old['books']:
        bid=base['id'];entry=approved[bid];annot=annotations[bid];review=copy.deepcopy(safety_by[bid])
        assert entry['title'] == json.loads(base['authoredBookJSON'])['title'], 'v4 approved titles must match pinned v3'
        authored=copy.deepcopy(json.loads(base['authoredBookJSON']))
        authored.update(title=entry['title'],status='v4-approved-text-metadata-review-candidate',sourceBookID=bid)
        lineage=copy.deepcopy(old_lineages[bid]);lineage['corpusID']=CORPUS_ID
        authored['variantID']=lineage['eventID'];authored['baseBookID']=lineage['baseBookID']
        pages=[]
        for index,(previous,text,patch) in enumerate(zip(authored['pages'],entry['pages'],annot['pages'])):
            n=index+1;assert patch['pageNumber']==n
            sid=f'p56_v4_{bid}_p{n:02d}';pointer=len(sources);digest=sha(text)
            sources.append(dict(id=sid,kind='authoredFullPage',text=text,sha256UTF8=digest))
            semantics=copy.deepcopy(patch['semantics']);art=copy.deepcopy(patch['artHandoff'])
            # Only page-context evidence: no unsupported atomic/action approval.
            for action in semantics['actions']:
                action.update(evidenceSourceID=sid,evidenceText=text,atomicActionMappingApproved=False)
            art.update(assetRuleApproval=False,runtimeArt=None)
            previous.update(text=text,semantics=semantics,artHandoff=art,sentenceSourceIDs=[],editorialIntensity=patch['intensity'])
            previous['provenance']=dict(complete=True,partCount=1,parts=[dict(order=0,sourceKind='pilotAuthoredFullPage',sourceID=sid,sourceTextDigest=digest,templateID=authored['blueprintID'],sourcePointer=f'sources.json#/sources/{pointer}',contexts=previous['context'])])
            causal=copy.deepcopy(patch['causalEvidence']);causal.update(bookID=bid,pageNumber=n,parentSourceID=sid,quoteSHA256=sha(causal['quote']))
            assert causal['quote'] in text
            # Agent may specify attribution page if a pronoun uses earlier naming.
            ap=causal.pop('attributionPageNumber',n);causal['attributionSourceID']=f'p56_v4_{bid}_p{ap:02d}'
            evidence.append(causal)
            t=template(text)
            pages.append(dict(number=n,beat=previous['role'],actorIDs=patch['actorIDs'],causalEvidence=causal,templateID='p56_runtime_'+sid,templateText=t,templateSHA256=sha(t),parentSourceID=sid,parentSHA256=digest,parentText=text,parentPointer=f'{CORPUS_ID}/sources.json#/sources/{pointer}',parentSourceIndex=pointer,semantics=semantics,artHandoff=art,intensity=patch['intensity'],settingID=previous['context']['settingID']))
        raw=write(CORPUS/'books'/f'{bid}.json',authored)
        manifest.append(dict(id=bid,file=f'books/{bid}.json',sha256FileBytes=sha(raw)))
        book={k:copy.deepcopy(base[k]) for k in ['id','structureID','mechanism','mode','companionID','worldID','discoveryID']}
        book.update(titleTemplate=template(entry['title']),authoredBookJSON=raw,authoredBookSHA256=sha(raw),pages=pages)
        books.append(book);lineages.append(lineage)
        review.update(bookSHA256FileBytes=sha(raw))
        for rp,page in zip(review['pages'],pages):
            rp.update(bookID=bid,sourceID=page['parentSourceID'],sourceSHA=page['parentSHA256'],sourceSHA256UTF8=page['parentSHA256'])
            for ev in rp['evidence']:
                ev['sourceID']=pages[ev['pageNumber']-1]['parentSourceID']
                assert ev['quote'] in pages[ev['pageNumber']-1]['parentText']
        review['title'].update(sourceText=entry['title'],sourceSHA256UTF8=sha(entry['title']),evidence=entry['title'])
        safety_books.append(review)
    source_bytes=write(CORPUS/'sources.json',dict(schema='magicpaper.p56.voice-v4.sources.v1',sources=sources))
    causal_bytes=write(CORPUS/'causal-evidence.json',dict(schema='magicpaper.p56.causal-evidence.v1',records=evidence))
    write(CORPUS/'manifest.json',dict(packageID=CORPUS_ID,inputs=inputs,books=manifest,productionEnabled=False,artApproved=False))
    bound_review={k:v for k,v in safety.items() if k!='books'};bound_review['books']=safety_books
    write(REVIEW/'content-safety-annotations.json',bound_review)
    payload={k:copy.deepcopy(old[k]) for k in ['engineBehaviorID','productionEnabled','artApproved','companions','settings','worldID','structures']}
    payload.update(schemaVersion=2,packageVersion=HERE.name,corpora=[dict(id=CORPUS_ID,sourcesJSON=source_bytes,sourcesSHA256=sha(source_bytes),causalEvidenceJSON=causal_bytes,causalEvidenceSHA256=sha(causal_bytes))],books=books,bookLineages=lineages,safetyReview=bound_review)
    raw=write(HERE/'payload.json',payload)
    write(HERE/'manifest.json',dict(schemaVersion=2,packageVersion=HERE.name,engineBehaviorID=payload['engineBehaviorID'],payloadSHA256=sha(raw),productionEnabled=False,artApproved=False,activationStatus='candidate-pending-validation'))
    print(json.dumps(dict(books=len(books),pages=len(sources),sha256=sha(raw))))
if __name__=='__main__': main()
