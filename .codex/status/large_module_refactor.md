# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation contact-window fixture test-family extraction.

Status:
Selected.

Selected slice:
Move the four contiguous contact-intent, contact-intent-summary,
refreshed-window, and source-window-lineage fixture tests into a focused module
with one shared builder owner.

Why this slice:
After the activity-artifact split, `validation_test.exs` is 16,260 lines. Tests
6,421-6,669 form a coherent contact-window planning provenance family and end
before spacecraft-state fixtures. Their eight builders are also used by the
deterministic aggregate, so they will move to a shared support owner imported
by both modules.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact contact intent,
window provenance, validation, stale-data coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/contact_window_fixture_test.exs`
- `test/support/validation/contact_window_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted contact-window fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All four tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Validation activity-artifact fixture extraction published as `15a58b38`: the
focused module passed 6/6, the parent passed 140/140, and all seven Validation
modules preserved the 181-test aggregate with no duplicate names. Format, diff
hygiene, dependency-closure checks, and bounded review were clean.

Next candidate:
Refresh the adjacent contact-intent, refreshed-window lineage, and spacecraft
state fixture clusters in the 16,260-line parent. Select only a coherent
multi-test boundary and move deterministic-aggregate builders to one shared
support owner rather than copying them.

Blocked:
No.
