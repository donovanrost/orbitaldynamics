# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation candidate-refresh freshness/budget replay test-family extraction.

Status:
Selected.

Selected slice:
Move the two contiguous candidate-refresh freshness and refresh-budget replay
tests into a focused module with one shared freshness/budget builder owner.

Why this slice:
After the filter/rejection split, `validation_test.exs` is 6,047 lines. Tests
1,645-1,773 form a coherent freshness/budget replay family and end before
station-calendar replay. Their six helpers form a complete closure and only
depend on the shared replay `result_set/1` owner.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact candidate-refresh
freshness and refresh-budget replay schema checks, stale source-budget coverage,
and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/candidate_refresh_freshness_budget_replay_fixture_test.exs`
- `test/support/validation/candidate_refresh_freshness_budget_replay_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted candidate-refresh freshness/budget replay fixture module directly
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
Validation candidate-refresh filter/rejection replay extraction published as
`226a6512`: the focused module passed 2/2, the parent passed 49/49, and all
thirty-three Validation modules preserved the 181-test aggregate with no
duplicate names. Format, diff hygiene, exact-source and dependency-closure
checks, and bounded review were clean.

Next candidate:
Map the candidate-refresh station-calendar and contact-allocation contradiction
replay families following the freshness/budget pair. Preserve source-report
assertion depth and reuse the shared replay result-set builder; stop before the
curated candidate-rejection report family.

Blocked:
No.
