# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation candidate-state artifact fixture test-family extraction.

Status:
Selected.

Selected slice:
Move the five contiguous candidate-rejection report, candidate-diff row, and
JSON/CCSDS OPM/OEM accepted-planning-state fixture tests into a focused module
with one shared candidate-state fixture owner.

Why this slice:
After the station/allocation split, `validation_test.exs` is 5,498 lines. Tests
1,655-1,971 form a coherent candidate-state artifact family and end before
campaign request lint. Their ten raw/observation helpers form a complete JSON
fixture closure; only the five observation helpers remain deterministic
aggregate consumers.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact candidate
rejection/diff and accepted-planning-state schema checks, CCSDS provenance
coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/candidate_state_fixture_test.exs`
- `test/support/validation/candidate_state_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted candidate-state artifact fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All five tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Validation candidate-refresh station/allocation replay extraction published as
`823263d2`: the focused module passed 2/2, the parent passed 45/45, and all
thirty-five Validation modules preserved the 181-test aggregate with no
duplicate names. Format, diff hygiene, exact-source and dependency-closure
checks, and bounded review were clean.

Next candidate:
Map the campaign request lint, capability catalog, and environment capability
fixture families following candidate state. Split only a coherent artifact
family with complete helper closure.

Blocked:
No.
