# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation candidate-refresh base fixture test-family extraction.

Status:
Selected.

Selected slice:
Move the two contiguous candidate-refresh base artifact and resource-provenance
fixture tests into a focused module with one shared builder owner.

Why this slice:
After the model-acceptance/safety-case split, `validation_test.exs` is 8,484
lines. Tests 1,602-1,704 form the candidate-refresh base artifact/provenance
family and end before domain-specific replay coverage. Their four
observation/raw builders form one closure; only the two observation builders
remain needed by the deterministic aggregate.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact candidate-refresh
artifact and resource-provenance schema checks, stale-provenance coverage, and
deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/candidate_refresh_base_fixture_test.exs`
- `test/support/validation/candidate_refresh_base_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted candidate-refresh base fixture module directly
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
Validation model-acceptance/safety-case fixture extraction published as
`da789d0c`: the focused module passed 2/2, the parent passed 66/66, and all
twenty-six Validation modules preserved the 181-test aggregate with no duplicate
names. Format, diff hygiene, exact-source and dependency-closure checks, and
bounded review were clean.

Next candidate:
Map the candidate-refresh contact contention and contact-intent replay tests
beginning after the base fixture pair. Preserve replay-domain boundaries and
move only a complete helper closure; stop before resource-projection replay.

Blocked:
No.
