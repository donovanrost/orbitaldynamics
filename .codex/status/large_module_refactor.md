# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation contact-window fixture test-family extraction.

Status:
Published as `3b06e3fa`.

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
Four byte-identical contact-window family tests moved into a 266-line focused
module. Eight observation/raw-fixture builders now have one 47-line shared
support owner; the parent imports only the four observation builders used by
its deterministic aggregate, with no private residue. The parent fell from
16,260 to 15,983 lines. Total test/support/loader LOC grew by 37 lines for
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
Refresh the adjacent spacecraft-state, remaining-horizon, and maneuver outcome
fixture cluster in the 15,983-line parent. Select only a coherent multi-test
boundary and move deterministic-aggregate builders to one shared support owner
rather than copying them.

Blocked:
No.
