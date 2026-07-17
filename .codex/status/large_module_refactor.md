# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation activity-artifact fixture test-family extraction.

Status:
Selected.

Selected slice:
Move the six contiguous planned-activity, activity-template, subsystem-model
capability, realized-activity, plan-delta, and candidate-activity fixture tests
into a focused module with one shared builder owner.

Why this slice:
After the policy-bundle split, `validation_test.exs` is 16,700 lines. Tests
6,410-6,797 form a coherent six-test activity lifecycle family and end before
contact-intent fixtures. Their fourteen builders are also used by the
deterministic aggregate, so they will move to a shared support owner imported
by both modules.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact activity model,
state, validation, stale-data coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/activity_artifact_fixture_test.exs`
- `test/support/validation/activity_artifact_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted activity-artifact fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All six tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Validation policy-bundle fixture extraction published as `757d86f8`: the focused
module passed 6/6, the parent passed 146/146, and all six Validation modules
preserved the 181-test aggregate with no duplicate names. Format, diff hygiene,
dependency-closure checks, and bounded review were clean.

Next candidate:
Refresh the adjacent planned/activity-template/subsystem/realized/candidate
activity fixture cluster in the 16,700-line parent. Select only a coherent
multi-test boundary and move deterministic-aggregate builders to one shared
support owner rather than copying them.

Blocked:
No.
