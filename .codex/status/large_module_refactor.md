# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation candidate-refresh filter/rejection replay test-family extraction.

Status:
Selected.

Selected slice:
Move the two contiguous candidate-refresh contact-filter and
candidate-rejection replay tests into a focused module with one shared
filter/rejection builder owner.

Why this slice:
After the capacity/filter split, `validation_test.exs` is 6,361 lines. Tests
1,639-1,802 form a coherent filter/rejection replay family and end before
freshness replay. Their six helpers form a complete closure and only depend on
the shared replay `result_set/1` owner.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact candidate-refresh
contact-filter and candidate-rejection replay schema checks, stale
filter/rejection coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/candidate_refresh_filter_rejection_replay_fixture_test.exs`
- `test/support/validation/candidate_refresh_filter_rejection_replay_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted candidate-refresh filter/rejection replay fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
Both tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Validation candidate-refresh capacity/filter replay extraction published as
`156760a6`: the focused module passed 2/2, the parent passed 51/51, and all
thirty-two Validation modules preserved the 181-test aggregate with no duplicate
names. Format, diff hygiene, exact-source and dependency-closure checks, and
bounded review were clean.

Next candidate:
Map the candidate-refresh freshness and refresh-budget replay families following
the filter/rejection pair. Preserve stale-source assertion depth and reuse the
shared replay result-set builder; stop before station-calendar replay.

Blocked:
No.
