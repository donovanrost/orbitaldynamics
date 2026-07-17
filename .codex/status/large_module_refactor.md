# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation operational-readiness artifact fixture test-family extraction.

Status:
Ready to publish.

Selected slice:
Move the five contiguous operator-review, operational-readiness,
execution-boundary, import-eligibility, and readiness-gate fixture tests into a
focused module with one shared operational-readiness fixture owner.

Why this slice:
After the contact-allocation split, `validation_test.exs` is 2,567 lines. Tests
359-922 validate the artifact-only readiness handoff from operator review
through readiness gates as one contiguous family. Ten local observation/raw
helpers form the closure. Five observation helpers remain consumed by the
parent's deterministic aggregate report, and the readiness raw fixture remains
consumed by its quality-gate builder, so one shared support owner makes both
cross-module dependencies explicit.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact readiness
handoff schema checks, stale gate/count/boundary coverage, and deterministic
aggregate reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/operational_readiness_fixture_test.exs`
- `test/support/validation/operational_readiness_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted operational-readiness fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All five tests move mechanically with order and assertion strength unchanged;
ten shared builders have one exact owner, the parent retains only its six
required imports, focused and parent files pass, all 181 test names remain
unique, and bounded review finds no blocker.

Outcome:
All five operational-readiness artifact tests moved into
`operational_readiness_fixture_test.exs` with order and assertion strength
unchanged. Ten fixture helpers moved exactly, apart from the required `defp` to
`def` visibility change, into `OperationalReadinessFixtures`. The focused
module imports the complete helper closure. The parent imports only the five
observation helpers required by its deterministic aggregate report plus the raw
readiness fixture required by its quality-gate builder. The parent shrank from
2,567 to 1,968 lines. The focused test file is 583 lines and the support owner
is 54 lines; explicit shared ownership adds 39 lines across the relevant test
and support files.

Verification gaps:
- Focused operational-readiness fixture module: 5/5 passed.
- Remaining parent validation module: 10/10 passed.
- Full Validation family: 45 modules, 181/181 passed.
- Exact-source audit: five tests, ten helpers, and the private JSON loader
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
Map the remaining quality-gate report and derived-summary fixture sequence.
Split only the complete family, including the stale copied-source challenge,
with explicit readiness-fixture reuse.

Blocked:
No.
