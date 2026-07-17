# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation quality-gate artifact fixture test-family extraction.

Status:
Selected.

Selected slice:
Move the eight contiguous quality-gate report, derived-summary, checked-in
unavailable-resource, and stale copied-source fixture tests into a focused
module with one shared quality-gate fixture owner.

Why this slice:
After the operational-readiness split, `validation_test.exs` is 1,968 lines.
Tests 369-1,178 validate the primary quality-gate report, five derived summary
contracts, the checked-in unavailable-resource summary, and copied-source
challenge handoffs as one contiguous family. Fourteen local observation/raw
helpers form the closure. Seven observation helpers remain consumed by the
parent's deterministic aggregate report, while the primary quality-gate
builder reuses the readiness raw fixture from its existing support owner.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact quality-gate and
derived-summary schema checks, stale copied-source coverage, unavailable
resource/training/schema-validation coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/quality_gate_fixture_test.exs`
- `test/support/validation/quality_gate_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted quality-gate fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All eight tests move mechanically with order and assertion strength unchanged;
fourteen shared builders have one exact owner, the parent retains only its
seven deterministic-report imports, focused and parent files pass, all 181 test
names remain unique, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Validation operational-readiness artifact fixture extraction published as
`6e3edacb`: the focused module passed 5/5, the parent passed 10/10, and all
forty-five Validation modules preserved the 181-test aggregate with no
duplicate names. Format, diff hygiene, exact-source and ownership-closure
checks, and bounded review were clean.

Next candidate:
Reassess the two remaining generic fixture-engine tests after the quality-gate
family moves. Keep them together unless a separate responsibility boundary
improves navigation and focused verification.

Blocked:
No.
