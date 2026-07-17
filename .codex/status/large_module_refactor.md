# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation link-capacity fixture test-family extraction.

Status:
Verified and reviewed; ready to publish.

Selected slice:
Move the three contiguous link-capacity report, link-capacity summary, and
relay data-path summary fixture tests into a focused module with one shared
builder owner.

Why this slice:
After the contact contention split, `validation_test.exs` is 12,095 lines.
Tests 7,119-7,424 form a coherent link-capacity-to-relay family and end before
maneuver-review fixtures. Their six observation/raw builders form one closure;
only observation builders remain needed by the deterministic aggregate.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact link capacity,
relay path, stale-data coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/link_capacity_fixture_test.exs`
- `test/support/validation/link_capacity_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted link-capacity fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All three tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Three byte-identical link-capacity family tests moved into a 321-line focused
module. Six observation/raw builders now have one 38-line shared support owner;
the parent imports only the three aggregate observation builders, with no
private residue. The parent fell from 12,095 to 11,769 lines. Total
test/support/loader LOC grew by 34 lines for explicit ownership without helper
duplication. All 181 Validation test names remain unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation contact contention fixture extraction published as `811bf261`: the
focused module passed 5/5, the parent passed 98/98, and all seventeen Validation
modules preserved the 181-test aggregate with no duplicate names. Format, diff
hygiene, dependency-closure checks, and bounded review were clean.

Next candidate:
Refresh the adjacent maneuver-review, Monte Carlo reproducibility, and Pareto
frontier fixture cluster in the 11,769-line parent. Select only a coherent
multi-test boundary and move shared builders to one support owner rather than
copying them.

Blocked:
No.
