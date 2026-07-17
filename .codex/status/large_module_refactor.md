# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation station reservation/provider fixture test-family extraction.

Status:
Selected.

Selected slice:
Move the nine contiguous stale reservation-hold, station reservation/review/hold
summary, import-readiness, precedence, provider, and counteroffer fixture tests
into a focused module with one shared builder owner.

Why this slice:
After the schema-compatibility split, `validation_test.exs` is 9,952 lines.
Tests 1,582-2,448 form a coherent reservation-to-provider-counteroffer family
and end before model-acceptance fixtures. Their 24 observation/raw/generated
builders form one closure; only twelve observation builders remain needed by
the deterministic aggregate.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact station
reservation, hold, precedence, provider, counteroffer, stale-data coverage, and
deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/station_reservation_fixture_test.exs`
- `test/support/validation/station_reservation_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted station reservation/provider fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All nine tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Validation schema-compatibility fixture extraction published as `42299354`: the
focused module passed 4/4, the parent passed 77/77, and all twenty-four
Validation modules preserved the 181-test aggregate with no duplicate names.
Format, diff hygiene, dependency-closure checks, and bounded review were clean.

Next candidate:
Map the nine-test station reservation/provider fixture cluster spanning stale
reservation hold through provider counteroffer summary in the 9,952-line
parent. Move only a complete helper closure with retained cross-family
consumers imported explicitly; leave the generic tolerance/determinism tail in
place.

Blocked:
No.
