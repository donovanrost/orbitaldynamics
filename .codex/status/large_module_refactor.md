# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation contact-allocation artifact fixture test-family extraction.

Status:
Published as `8e3f7616`.

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
All five contact-allocation artifact tests moved into
`contact_allocation_fixture_test.exs` with order and assertion strength
unchanged. Six fixture helpers moved exactly, apart from the required `defp` to
`def` visibility change, into `ContactAllocationFixtures`. The focused module
imports the report/raw helper pair it consumes, while the parent imports the
five observation helpers still required by its deterministic aggregate report.
The parent shrank from 3,064 to 2,567 lines. The focused test file is 486 lines
and the shared support owner is 46 lines; explicit shared ownership adds 36
lines across the relevant test and support files.

Verification gaps:
- Focused contact-allocation fixture module: 5/5 passed.
- Remaining parent validation module: 15/15 passed.
- Full Validation family: 44 modules, 181/181 passed.
- Exact-source audit: five tests, six helpers, and both private JSON loaders
  exact; all 181 test names remain unique.
- `mix format --check-formatted` and `git diff --check` passed.
- Independent bounded review found no blocker.

Last completed slice:
Validation contact-allocation artifact fixture extraction published as
`8e3f7616`: the focused module passed 5/5, the parent passed 15/15, and all
forty-four Validation modules preserved the 181-test aggregate with no
duplicate names. Format, diff hygiene, exact-source and ownership-closure
checks, and bounded review were clean.

Next candidate:
Reassess the remaining parent after the allocation family moves. Prefer the
next contiguous responsibility boundary whose complete helper closure can move
without pulling the generic tolerance or deterministic aggregate tests.

Blocked:
No.
