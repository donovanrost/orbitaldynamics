# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation candidate-refresh base fixture test-family extraction.

Status:
Published as `a37bc4ae`.

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
Two byte-identical candidate-refresh base artifact/provenance tests moved into a
116-line focused module. All four observation/raw builders now have one 29-line
shared support owner; the parent imports only the two aggregate observation
builders. The parent fell from 8,484 to 8,367 lines. Total
test/support/loader LOC grew by 29 lines for explicit ownership without helper
duplication. All 181 Validation test names remain unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation candidate-refresh base fixture extraction published as `a37bc4ae`:
the focused module passed 2/2, the parent passed 64/64, and all twenty-seven
Validation modules preserved the 181-test aggregate with no duplicate names.
Format, diff hygiene, exact-source and dependency-closure checks, and bounded
review were clean.

Next candidate:
Map the candidate-refresh contact contention and contact-intent replay tests
beginning after the base fixture pair. Their six family-specific helpers depend
on the generic `result_set/1` builder shared by the remaining replay families;
establish one explicit shared owner rather than duplicating it, and stop before
resource-projection replay.

Blocked:
No.
