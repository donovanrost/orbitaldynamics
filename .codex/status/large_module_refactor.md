# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation station reservation/provider fixture test-family extraction.

Status:
Ready to publish.

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
Nine byte-identical station reservation/provider family tests moved into a
900-line focused module. All 24 observation/raw/generated builders now have one
188-line shared support owner; the parent imports only the twelve aggregate
observation builders and no longer owns `StationCalendar`. The parent fell from
9,952 to 8,921 lines. Total test/support/loader LOC grew by 58 lines for explicit
ownership without helper duplication. All 181 Validation test names remain
unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation schema-compatibility fixture extraction published as `42299354`: the
focused module passed 4/4, the parent passed 77/77, and all twenty-four
Validation modules preserved the 181-test aggregate with no duplicate names.
Format, diff hygiene, dependency-closure checks, and bounded review were clean.

Next candidate:
Map the adjacent model-acceptance and validation safety-case fixture tests,
currently lines 1,596-2,012 in the 8,921-line parent. Their four raw/observation
helpers form a closed validation-evidence family, while the two observation
helpers remain deterministic-aggregate consumers; stop before candidate-refresh
replay coverage.

Blocked:
No.
