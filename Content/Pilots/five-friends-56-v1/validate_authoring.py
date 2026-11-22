"""Offline authoring integrity check. This does NOT validate StoryEngine acceptance.
Run only in the final verification phase: python3 <this-file>.
"""
import hashlib, json
from pathlib import Path
ROOT=Path(__file__).resolve().parent

def digest(text): return hashlib.sha256(text.encode('utf-8')).hexdigest()
def read(path): return json.loads(path.read_text())
def validate():
    manifest=read(ROOT/'manifest.json')
    source_doc=read(ROOT/'sources.json'); sources=source_doc['sources']
    ids=[s['id'] for s in sources]
    assert len(ids)==len(set(ids)), 'duplicate source ID'
    by_id={s['id']:s for s in sources}
    for source in sources:
        assert source['sha256UTF8']==digest(source['text']), source['id']
    assert manifest['sourcePayloadSHA256FileBytes']==hashlib.sha256((ROOT/'sources.json').read_bytes()).hexdigest()
    structures=read(ROOT/'structures.json')['structures']
    assert len(structures)==9
    allowed={(s['planLabel'],c) for s in structures for c in s['allowedCompanionIDs']}
    assert len(allowed)==30
    actual=set(); pages=0; cells={}; warnings=[]
    for entry in manifest['books']:
        path=ROOT/entry['file']
        assert entry['sha256FileBytes']==hashlib.sha256(path.read_bytes()).hexdigest(),path
        book=read(path); actual.add((book['planLabel'],book['context']['companionID']))
        assert len(book['pages'])==8 and not book['runtimeCompatible']
        cell=(book['context']['companionID'],book['context']['mode'])
        cells.setdefault(cell,set()).add(book['mechanismKey'])
        for i,page in enumerate(book['pages'],1):
            pages+=1
            assert page['pageNumber']==i and page['context']==book['context']
            assert '{' not in page['text'] and '}' not in page['text'], 'unfilled token'
            parts=page['provenance']['parts']; assert len(parts)==page['provenance']['partCount']==1
            source=by_id[parts[0]['sourceID']]
            assert source['text']==page['text'] and parts[0]['sourceTextDigest']==digest(page['text'])
            pointer_index=int(parts[0]['sourcePointer'].rsplit('/',1)[1]); assert sources[pointer_index]['id']==source['id']
            assert ' '.join(by_id[x]['text'] for x in page['sentenceSourceIDs'])==page['text']
            assert page['semantics']['subjects'] and page['semantics']['actions']
            assert page['artHandoff']['assetRuleApproval'] is False and page['artHandoff']['runtimeArt'] is None
            assert page['previousPageNumber']==(i-1 if i>1 else None)
            assert page['nextPageNumber']==(i+1 if i<8 else None)
        if book['context']['mode']=='bedtime':
            assert book['context']['settingID']=='pilot56_setting_forest_edge_room_v1'
            assert book['pages'][-1]['editorialIntensity']==0
            assert all(p['editorialIntensity']<=1 for p in book['pages'])
            assert 'Orman Kıyısındaki Oda' in book['pages'][0]['text']
            assert 'Orman Kıyısındaki Oda' in book['pages'][-1]['text']
        words=sum(len(p['text'].split()) for p in book['pages'])
        assert words==entry['wordCountWhitespace']
        if not 144<=words<=304: warnings.append({'book':book['id'],'words':words,'reason':'outside historical 144–304 reference; runtime age budget unverified'})
    assert actual==allowed and len(manifest['books'])==30 and pages==240
    assert len(cells)==15 and all(len(mechanisms)==2 for mechanisms in cells.values())
    return {'status':'offline-authoring-integrity-only','books':30,'pages':pages,'structures':9,'cells':15,
      'sourceRecords':len(sources),'wordBudgetWarnings':warnings,
      'runtimeAcceptance':'NOT RUN','independentEditorialAcceptance':'NOT COMPLETE','artAcceptance':'NOT APPROVED'}

if __name__=='__main__': print(json.dumps(validate(),ensure_ascii=False,indent=2))
