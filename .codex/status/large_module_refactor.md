# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation resource-pressure handoff fixture test-family extraction.

Status:
Ready to publish.

Selected slice:
Move the resource-pressure handoff fixture test into a focused module with one
shared cross-handoff fixture owner.

Why this slice:
After the policy-decision split, `validation_test.exs` is 3,230 lines. Test
1,718-1,861 validates quality-gate, readiness, operator-review, and import
handoffs as one cross-artifact family. Six local observation/raw helpers form
its closure, while the quality-gate and readiness raw fixtures remain owned by
the existing readiness-replay support module.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact cross-handoff
resource-pressure schema checks, stale handoff coverage, and deterministic
reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/resource_pressure_handoff_fixture_test.exs`
- `test/support/validation/resource_pressure_handoff_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted resource-pressure handoff fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
The handoff test moves mechanically with order and assertion strength unchanged;
shared builders have one exact owner, existing raw source ownership is reused,
focused and parent files pass, names remain unique, and bounded review finds no
blocker.

Outcome:
The single resource-pressure handoff test moved into
`resource_pressure_handoff_fixture_test.exs`. Six local fixture helpers moved
exactly, apart from the required `defp` to `def` visibility change, into one
shared support owner. The existing readiness and quality-gate raw fixtures
remain owned by `CandidateRefreshReadinessReplayFixtures`; the focused test and
new support module reuse them directly. The parent now imports only the four
aggregate observation helpers it still consumes and shrank from 3,230 to 3,064
lines. The focused test file is 165 lines and the support owner is 43 lines.

Verification gaps:
- Focused resource-pressure handoff module: 1/1 passed.
- Remaining parent validation module: 20/20 passed.
- Full Validation family: 43 modules, 181/181 passed.
- Exact-source audit: test, six local helpers, and private JSON loader exact;
  two existing raw owners reused; all 181 test names remain unique.
- `mix format --check-formatted` and `git diff --check` passed.
- Independent bounded review found no blocker.

Last completed slice:
Validation policy-decision fixture extraction published as `a1c32f34`: the
focused module passed 2/2, the parent passed 21/21, and all forty-two Validation
modules preserved the 181-test aggregate with no duplicate names. Format, diff
hygiene, exact-source and dependency-closure checks, and bounded review were
clean.

Next candidate:
Map the contact-allocation report, reservation-conflict, station-pressure,
capacity-pack, and contact-allocation summary fixture sequence. Split only a
complete allocation artifact family with explicit shared helper ownership.

Blocked:
No.
