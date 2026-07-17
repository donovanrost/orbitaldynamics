# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation resource-safety handoff fixture test-family extraction.

Status:
Verified and reviewed; ready to publish.

Selected slice:
Move the two contiguous resource-projection battery-handoff and stale
derived-margin fixture tests into a focused module with one shared builder
owner.

Why this slice:
After the resource-projection report split, `validation_test.exs` is 11,281
lines. Tests 7,139-7,286 form a coherent resource-safety handoff family and end
before resource-summary fixtures. Their eight core/operator/Cadence/stale-margin
observation and raw builders form one closure; only observation builders remain
needed by the deterministic aggregate.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact battery handoff,
stale-margin, cross-artifact observation coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/resource_safety_fixture_test.exs`
- `test/support/validation/resource_safety_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted resource-safety handoff fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
Both tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Two byte-identical resource-safety handoff family tests moved into a 167-line
focused module. Ten core/operator/Cadence projection and stale-margin
observation/raw builders now have one 120-line shared support owner; the parent
imports only the five aggregate observation builders, with no private residue.
The parent fell from 11,281 to 11,031 lines, and its now-unused
`ResourceFilter`/`ResourceProjection` aliases moved to support. Total
test/support/loader LOC grew by 38 lines for explicit ownership without helper
duplication. All 181 Validation test names remain unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation resource-projection fixture extraction published as `385d421e`: the
focused module passed 2/2, the parent passed 90/90, and all twenty Validation
modules preserved the 181-test aggregate with no duplicate names. Format, diff
hygiene, dependency-closure checks, and bounded review were clean.

Next candidate:
Refresh the adjacent resource-summary and resource-filter report/summary
fixture cluster in the 11,031-line parent. Select only a coherent multi-test
boundary and move shared builders to one support owner rather than copying
them.

Blocked:
No.
