# Reviewed discovery art implementation plan

Goal: add exact reviewed silver-bell narrative pins without widening unreviewed art matching.
Architecture: import c742ea7 provenance source unchanged; isolated app publishing policy validates actual composed source parts and bound subject; existing art model/resolver persists pins. Swift/JSON/CryptoKit/ImageIO/XCTest.

- [x] Inspect dirty ownership and apply c742ea7 delta excluding shared journal; no branchswitch or user-edit stash.
- [x] Read5notice and38recall exact prose; record narrow isolatedbellpolicy in spec. No blanketautoapproval.
- [x] Builder tests first for positive realcomposer plus mutationfailclosed and savedpin roundtrip; no interimruns perAGENTS.
- [x] Implement small reviewedbinder/policy and bellresource, keeping v1rules unchanged. Ownershipbuilder:StorySpotBinder/catalog/helper/newtests/artresources; root:modelimport/docs/verification. Do not edit ReaderImageLoader, Classic/Originals,engineprose/selection.
- [x] Independent correctness/spec review then final focused app/engine tests and devicebuild/render evidence asavailable. Record failures honestly, no completecoverageclaim.
- [x] Record sourceimport provenance, code/test results and commit onlyownedfiles; no push/merge request required.

Acceptance: exactsourceproof+sameboundcanonicalbell+cleanwholepage are necessary. Unknown/missing/corruptproofstays text. Existing art pins never rewritten. Saved reader uses pinnedfile. Existing strict10subjectrules retain allnegativebehavior. Broaderstates/age/mode/pagecoverage is explicitlyfuturework.

Final evidence (21 November): engine 11/0; app 96 total, 94 passed, 1 skipped, 1 failed in unchanged series eligibility assertion. All 22 art/provenance tests passed. No device install or new UI matrix; see handoff REPORT.md. Broader coverage remains uncertified.
