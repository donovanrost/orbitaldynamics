# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation candidate-refresh capacity/filter replay test-family extraction.

Status:
Ready to publish.

Selected slice:
Move the two contiguous candidate-refresh link-capacity and resource-filter
replay tests into a focused module with one shared capacity/filter builder owner.

Why this slice:
After the planning-feedback split, `validation_test.exs` is 6,747 lines. Tests
1,633-1,833 form a coherent capacity/filter replay family and end before
contact-filter replay. Their six helpers form a complete closure and only
depend on the shared replay `result_set/1` owner.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact candidate-refresh
link-capacity and resource-filter replay schema checks, stale source-report
coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/candidate_refresh_capacity_filter_replay_fixture_test.exs`
- `test/support/validation/candidate_refresh_capacity_filter_replay_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted candidate-refresh capacity/filter replay fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
Both tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Two byte-identical candidate-refresh capacity/filter replay tests moved into a
214-line focused module. Their six helpers now have one 197-line shared support
owner that reuses `result_set/1`; the parent imports only the two aggregate
observation builders. The parent fell from 6,747 to 6,361 lines. Total
test/support/loader LOC grew by 30 lines for explicit ownership without helper
duplication. All 181 Validation test names remain unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation candidate-refresh planning-feedback replay extraction published as
`78a7ecbf`: the focused module passed 2/2, the parent passed 53/53, and all
thirty-one Validation modules preserved the 181-test aggregate with no duplicate
names. Format, diff hygiene, exact-source and dependency-closure checks, and
bounded review were clean.

Next candidate:
Map the candidate-refresh contact-filter and candidate-rejection replay
families following the capacity/filter pair. Preserve filter/rejection
assertion depth and reuse the shared replay result-set builder. Their six
helpers form a closed family; stop before freshness replay.

Blocked:
No.
