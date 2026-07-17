# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation candidate-refresh station/allocation replay test-family extraction.

Status:
Published as `823263d2`.

Selected slice:
Move the two contiguous candidate-refresh station-calendar and
contact-allocation contradiction replay tests into a focused module with one
shared station/allocation builder owner.

Why this slice:
After the freshness/budget split, `validation_test.exs` is 5,813 lines. Tests
1,651-1,823 form the final coherent candidate-refresh replay family and end
before curated candidate-rejection artifacts. Their six helpers form a complete
closure and only depend on the shared replay `result_set/1` owner.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact candidate-refresh
station-calendar and contact-allocation contradiction replay schema checks,
stale allocation coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/candidate_refresh_station_allocation_replay_fixture_test.exs`
- `test/support/validation/candidate_refresh_station_allocation_replay_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted candidate-refresh station/allocation replay fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
Both tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Two byte-identical candidate-refresh station/allocation replay tests moved into
a 186-line focused module. Their six helpers now have one 158-line shared
support owner that reuses `result_set/1` and an exact private JSON loader; the
parent imports only the two aggregate observation builders and no longer owns
any direct `CandidateRefresh` or `result_set/1` dependency. The parent fell from
5,813 to 5,498 lines. Total test/support/loader LOC grew by 34 lines for
explicit ownership without helper duplication. All 181 Validation test names
remain unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation candidate-refresh station/allocation replay extraction published as
`823263d2`: the focused module passed 2/2, the parent passed 45/45, and all
thirty-five Validation modules preserved the 181-test aggregate with no
duplicate names. Format, diff hygiene, exact-source and dependency-closure
checks, and bounded review were clean.

Next candidate:
Map the curated candidate-rejection, candidate-diff row, and accepted-planning
state fixture families following the replay sequence. The five contiguous tests
and ten raw/observation helpers form one candidate-state artifact family ending
before campaign request lint.

Blocked:
No.
