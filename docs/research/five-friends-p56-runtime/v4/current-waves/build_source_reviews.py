"""Bind source-only wave reviews. Never constructs a runtime package or changes prose."""
from pathlib import Path
import copy,hashlib,json,re
ROOT=Path(__file__).resolve().parents[5]
HERE=Path(__file__).resolve().parent
CANONICAL=[f'{m}-{a}.json' for m in ['adventure','learning','bedtime'] for a in ['fox','hedgehog','owl','cat','bear']]
TOPICS={'darkness','alone','fear','weather','heights'}
def sha(s): return hashlib.sha256(s.encode() if isinstance(s,str) else s).hexdigest()
def write(p,o):
    p.parent.mkdir(parents=True,exist_ok=True);s=json.dumps(o,ensure_ascii=False,indent=2)+'\n';p.write_text(s);return s

def build(wave):
    corpus=ROOT/f'Content/Pilots/five-friends-56-wave{wave}-v1';out=HERE/f'wave{wave}'
    sem=json.loads((out/'semantic-review.json').read_text());safe=json.loads((out/'safety-review-content.json').read_text())
    sb={b['bookID']:b for b in sem['books']};safety={b['bookID']:b for b in safe['books']}
    sources=[];books=[];causal=[];bound=[];artbooks=[];inputfiles=[]
    for name in CANONICAL:
        p=corpus/'input'/name;raw=p.read_bytes();doc=json.loads(raw);inputfiles.append({'file':'input/'+name,'sha256':sha(raw)})
        mode,companion=doc['cell'].split('/')
        for index,original in enumerate(doc['books']):
            bid=original['sourceBookID'];patch=sb[bid];review=copy.deepcopy(safety[bid]);pages=[];handoff=[]
            for n,(text,annotation,rp) in enumerate(zip(original['pages'],patch['pages'],review['pages']),1):
                assert annotation['pageNumber']==rp['pageNumber']==n and annotation['sourceSHA256UTF8']==sha(text)
                sid=f'p56_wave{wave}_{bid}_p{n:02d}';pointer=f'input/{name}#/books/{index}/pages/{n-1}'
                sources.append(dict(id=sid,bookID=bid,pageNumber=n,text=text,sha256UTF8=sha(text),inputFileSHA256=sha(raw),inputPointer=pointer))
                a=copy.deepcopy(annotation);a.update(text=text,sourceID=sid,sourceSHA256UTF8=sha(text),sourcePointer=pointer)
                for action in a['semantics']['actions']:
                    action.update(evidenceSourceID=sid,evidenceText=text,atomicActionMappingApproved=False)
                e=a['causalEvidence'];assert e['quote'] in text;e.update(parentSourceID=sid,quoteSHA256=sha(e['quote']))
                a['artHandoff'].update(assetRuleApproval=False,runtimeArt=None);a['typedContractApproved']=False
                causal.append(dict(e,rawPageMove=a['rawPageMove'],typedContractApproved=False))
                rp.update(bookID=bid,sourceID=sid,sourceSHA=sha(text),sourceSHA256UTF8=sha(text))
                assert rp['status']=='reviewed' and set(rp['topics']).union(rp['topicExclusionRationale'])==TOPICS
                assert set(rp['topics']).isdisjoint(rp['topicExclusionRationale'])
                for evidence in rp['evidence']:
                    page=evidence['pageNumber'];assert evidence['quote'] in original['pages'][page-1]
                    evidence['sourceID']=f'p56_wave{wave}_{bid}_p{page:02d}'
                pages.append(a)
                handoff.append(dict(pageNumber=n,fullAuthoredText=text,previousPageText=original['pages'][n-2] if n>1 else None,nextPageText=original['pages'][n] if n<8 else None,sourceIdentity={'sourceID':sid,'sourceSHA256UTF8':sha(text),'inputPointer':pointer,'inputFileSHA256':sha(raw)},semantics=a['semantics'],specificArtNeeds=a['artHandoff'],typedContractApproved=False,atomicActionMappingApproved=False))
            blockers=[i for i in sem['blockers'] if i['sourceBookID']==bid]
            book=dict(schema='magicpaper.p56.wave-source-review.v1',id=bid,title=original['title'],context=patch['context'],originalInputBook=original,inputFileSHA256=sha(raw),inputBookPointer=f'input/{name}#/books/{index}',pages=pages,childAgencyAnnotation=patch['childAgency'],contentBlockers=blockers,runtimeCompatible=False,typedContractApproved=False,productionEnabled=False,artApproved=False)
            data=write(corpus/'books'/f'{bid}.json',book);books.append(dict(id=bid,file=f'books/{bid}.json',sha256FileBytes=sha(data),mode=mode,companionID=companion,structure=original['structure']))
            review['bookSHA256FileBytes']=sha(data);review['title'].update(sourceText=original['title'],sourceSHA256UTF8=sha(original['title']),evidence=original['title'])
            assert set(review['topics'])==set(review['title']['topics']).union(*(set(p['topics']) for p in review['pages']))
            assert set(review['emotions'])=={p['emotion'] for p in review['pages']}
            assert review['calmEligible']==not_any_tense(review['pages'])
            bound.append(review)
            artbooks.append(dict(bookID=bid,title=original['title'],bookSHA256FileBytes=sha(data),sourceSpecContext=patch['context'],contentBlockers=blockers,pages=handoff))
    assert len(books)==len(set(b['id'] for b in books))==90 and len(sources)==720
    source_data=write(corpus/'sources.json',dict(schema='magicpaper.p56.wave-source-evidence.v1',sources=sources))
    evidence_data=write(corpus/'causal-evidence.json',dict(schema='magicpaper.p56.authored-wave-evidence.v1',typedContractApproved=False,records=causal))
    write(corpus/'manifest.json',dict(corpusID=corpus.name,status='source-reviewed; runtime-not-implemented',books=books,inputs=inputfiles,sourcesSHA256=sha(source_data),causalEvidenceSHA256=sha(evidence_data),runtimeCompatible=False,typedContractApproved=False,productionEnabled=False,artApproved=False))
    safety_doc={k:v for k,v in safe.items() if k!='books'};safety_doc['books']=bound
    write(out/'content-safety-annotations.json',safety_doc)
    write(out/'art-handoff.json',dict(scope='90 authored books /720 source pages; not runtime-composed fixtures',typedContractApproved=False,productionEnabled=False,artApproved=False,books=artbooks))
    write(out/'binding-verification.json',dict(books=90,pages=720,exactPageQuotes=720,completeTopicDispositions=720,bookHashBindings=90,typedRuntimeValidated=False,contentBlockerBooks=len({x['sourceBookID'] for x in sem['blockers']}),status='source-binding-verified; content/runtime-acceptance-withheld'))
    print(json.dumps({'wave':wave,'books':len(books),'pages':len(sources),'blockers':len(sem['blockers'])}))

def not_any_tense(pages):return not any(p['emotion'] in ['unease','hesitation'] for p in pages)
if __name__=='__main__':
    for wave in [1,2]:build(wave)
