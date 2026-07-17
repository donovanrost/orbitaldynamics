# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation candidate-refresh resource/readiness replay test-family extraction.

Status:
Published as `d4df2765`.

Selected slice:
Move the three contiguous candidate-refresh resource-projection, quality-gate,
and operational-readiness replay tests into a focused module with one shared
source/replay builder owner.

Why this slice:
After the contact replay split, `validation_test.exs` is 8,057 lines. Tests
1,613-1,839 form a coherent resource/readiness replay family and end before
timeline activity replay. Their twelve replay helpers plus two checked-in source
fixture loaders form the complete closure; retained parent tests import the two
source loaders and three observation builders. The generic `result_set/1`
remains owned by the contact-replay support module.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact candidate-refresh
resource-projection, quality-gate, and operational-readiness replay schema
checks, stale source-report coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/candidate_refresh_readiness_replay_fixture_test.exs`
- `test/support/validation/candidate_refresh_readiness_replay_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted candidate-refresh resource/readiness replay fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All three tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Three byte-identical candidate-refresh resource/readiness replay tests moved
into a 242-line focused module. Their twelve replay helpers and two retained
source fixture loaders now have one 184-line shared support owner; the parent
imports only the three aggregate observation builders and two source loaders.
The parent fell from 8,057 to 7,667 lines. Total test/support/loader LOC grew by
37 lines for explicit ownership without helper duplication. All 181 Validation
test names remain unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation candidate-refresh resource/readiness replay extraction published as
`d4df2765`: the focused module passed 3/3, the parent passed 59/59, and all
twenty-nine Validation modules preserved the 181-test aggregate with no
duplicate names. Format, diff hygiene, exact-source and dependency-closure
checks, and bounded review were clean.

Next candidate:
Map the candidate-refresh timeline precondition, lifecycle-state,
activity-lifecycle, and transition-application replay sequence. Preserve the
existing timeline fixture owners and reuse the shared replay result-set builder.
Their sixteen helpers own all remaining parent `Timeline` calls; stop before
objective-gap replay.

Blocked:
No.
