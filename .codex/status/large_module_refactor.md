# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation state-and-maneuver fixture test-family extraction.

Status:
Verified and reviewed; ready to publish.

Selected slice:
Move the five contiguous spacecraft-state-estimate, realized-state-snapshot,
remaining-horizon, maneuver-execution-delta, and maneuver-recommendation fixture
tests into a focused module with one shared builder owner.

Why this slice:
After the contact-window split, `validation_test.exs` is 15,983 lines. Tests
6,429-6,698 form a coherent state-to-maneuver outcome family and end before
backend-policy fixtures. Their ten builders are also used by the deterministic
aggregate, so they will move to a shared support owner imported by both modules.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact state, horizon,
maneuver, validation, stale-data coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/state_maneuver_fixture_test.exs`
- `test/support/validation/state_maneuver_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted state-and-maneuver fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All five tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Five byte-identical state-and-maneuver family tests moved into a 289-line
focused module. Ten observation/raw-fixture builders now have one 56-line
shared support owner; the parent imports only the five observation builders
used by its deterministic aggregate, with no private residue. The parent fell
from 15,983 to 15,677 lines. Total test/support/loader LOC grew by 40 lines for
explicit ownership without helper duplication. All 181 Validation test names
remain unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation contact-window fixture extraction published as `3b06e3fa`: the
focused module passed 4/4, the parent passed 136/136, and all eight Validation
modules preserved the 181-test aggregate with no duplicate names. Format, diff
hygiene, dependency-closure checks, and bounded review were clean.

Next candidate:
Refresh the adjacent backend-acceptance, tolerance-policy, validation-record,
and validation-check fixture cluster in the 15,677-line parent. Select only a
coherent multi-test boundary and move deterministic-aggregate builders to one
shared support owner rather than copying them.

Blocked:
No.
