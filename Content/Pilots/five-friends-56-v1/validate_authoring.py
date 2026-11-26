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
    actual=set(); pages=0; cells={}; warnings=[]; page_by_key={}
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
            semantics=page['semantics']
            page_by_key[(book['id'],i)]=page
            assert semantics['metadataRevision']==2
            assert semantics['subjects'] and semantics['actions']
            present_ids={subject['subjectID'] for subject in semantics['subjects'] if subject['presence']=='present'}
            for action in semantics['actions']:
                actors=action['actorSubjectIDs']
                assert isinstance(actors,list) and actors and len(actors)==len(set(actors))
                assert all(actor in present_ids for actor in actors), 'action actor must be currently present'
                assert 'actorSubjectID' not in action, 'obsolete scalar/composite actor field'
                assert action['atomicActionMappingApproved'] is False
                assert action['evidenceSourceID']==source['id'] and action['evidenceText']==page['text']
            if book['planLabel']=='A3' and i==8:
                root=[subject for subject in semantics['subjects'] if subject['subjectID']=='pilot56_object_forked_root_v1']
                assert len(root)==1 and root[0]['presence']=='off-scene'
            if book['id']=='pilot56_book_a3_owl_v1' and i==3:
                assert 'pilot56_object_current_rest_root_v1' in present_ids
                assert any(subject['subjectID']=='pilot56_object_forked_root_v1' and subject['presence']=='remembered' for subject in semantics['subjects'])
            if book['planLabel']=='U2':
                assert '(kirpi)' not in semantics['propDescription'] and '(kedi)' not in semantics['propDescription'] and '(ayı)' not in semantics['propDescription'], 'cross-species prop list'

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
    ledger=read(ROOT/'editorial-revisions.json')
    assert ledger['revision']==3 and len(ledger['changes'])==12
    for change in ledger['changes']:
        assert digest(change['supersededText'])==change['supersededSHA256']
        assert digest(change['newText'])==change['newSHA256']
        assert change['supersededSourceID']!=change['newSourceID']
        current=by_id[change['newSourceID']]
        assert current['text']==change['newText'] and current['sha256UTF8']==change['newSHA256']
        assert change['supersededSourceID'] not in by_id
    revisions=ledger['metadataRevisions']
    assert len(revisions)==1 and revisions[0]['revision']==2
    metadata_entries=revisions[0]['pages']; metadata_keys=set()
    for item in metadata_entries:
        key=(item['bookID'],item['pageNumber']); assert key not in metadata_keys
        metadata_keys.add(key); page=page_by_key[key]
        assert item['previousSemantics']!=item['newSemantics']
        assert item['newSemantics']==page['semantics']
        assert item['sourceID']==page['provenance']['parts'][0]['sourceID']
    assert metadata_keys==set(page_by_key) and len(metadata_entries)==240
    assert actual==allowed and len(manifest['books'])==30 and pages==240
    assert len(cells)==15 and all(len(mechanisms)==2 for mechanisms in cells.values())
    return {'status':'offline-authoring-integrity-only','books':30,'pages':pages,'structures':9,'cells':15,
      'sourceRecords':len(sources),'wordBudgetWarnings':warnings,
      'runtimeAcceptance':'NOT RUN','independentEditorialAcceptance':'NOT COMPLETE','artAcceptance':'NOT APPROVED'}

if __name__=='__main__': print(json.dumps(validate(),ensure_ascii=False,indent=2))
