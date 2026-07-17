# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation candidate-refresh timeline replay test-family extraction.

Status:
Selected.

Selected slice:
Move the four contiguous candidate-refresh timeline precondition,
lifecycle-state, activity-lifecycle, and transition-application replay tests
into a focused module with one shared timeline replay builder owner.

Why this slice:
After the resource/readiness split, `validation_test.exs` is 7,667 lines. Tests
1,622-1,971 form a coherent timeline replay family and end before objective-gap
replay. Their sixteen helpers form the complete closure, depend on two existing
timeline fixture owners, and contain every remaining parent `Timeline` call.
The generic `result_set/1` remains owned by the contact-replay support module.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact candidate-refresh
timeline precondition/lifecycle/transition replay schema checks, stale
timeline-source coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/candidate_refresh_timeline_replay_fixture_test.exs`
- `test/support/validation/candidate_refresh_timeline_replay_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted candidate-refresh timeline replay fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All four tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Validation candidate-refresh resource/readiness replay extraction published as
`d4df2765`: the focused module passed 3/3, the parent passed 59/59, and all
twenty-nine Validation modules preserved the 181-test aggregate with no
duplicate names. Format, diff hygiene, exact-source and dependency-closure
checks, and bounded review were clean.

Next candidate:
Map the candidate-refresh objective-gap and constraint replay families
following the timeline sequence. Preserve their multi-report assertion depth
and reuse the shared replay result-set builder; stop before link-capacity replay.

Blocked:
No.
