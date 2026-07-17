# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation contact-allocation artifact fixture test-family extraction.

Status:
Selected.

Selected slice:
Move the five contiguous contact-allocation report, reservation-conflict,
station-pressure, capacity-pack, and allocation-summary fixture tests into a
focused module with one shared contact-allocation fixture owner.

Why this slice:
After the resource-pressure split, `validation_test.exs` is 3,064 lines. Tests
1,724-2,192 validate the primary contact-allocation report and its four derived
summary artifacts as one contiguous family. Six local observation/raw helpers
form the closure. The five observation helpers remain consumed by the parent's
deterministic aggregate report test, so one shared support owner makes that
cross-module dependency explicit.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact allocation and
derived-summary schema checks, stale derived-count/grouping coverage, and
deterministic aggregate reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/contact_allocation_fixture_test.exs`
- `test/support/validation/contact_allocation_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted contact-allocation fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All five tests move mechanically with order and assertion strength unchanged;
six shared builders have one exact owner, the focused and parent files pass,
all 181 test names remain unique, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Validation resource-pressure handoff fixture extraction published as
`0f28b6a4`: the focused module passed 1/1, the parent passed 20/20, and all
forty-three Validation modules preserved the 181-test aggregate with no
duplicate names. Format, diff hygiene, exact-source and ownership-closure
checks, and bounded review were clean.

Next candidate:
Reassess the remaining parent after the allocation family moves. Prefer the
next contiguous responsibility boundary whose complete helper closure can move
without pulling the generic tolerance or deterministic aggregate tests.

Blocked:
No.
