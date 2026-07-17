# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation timeline transition-application fixture test-family extraction.

Status:
Selected.

Selected slice:
Move the four contiguous timeline transition-application summary,
selected-integrity summary, report, and selected-integrity report fixture tests
into a focused module with one shared builder owner.

Why this slice:
After the timeline preservation split, `validation_test.exs` is 14,091 lines.
Tests 6,560-6,936 form a coherent transition-application summary/report family
and end before timeline-feedback fixtures. Their eight observation/raw builders
form one closure; only observation builders remain needed by the deterministic
aggregate.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact transition
application, selected-integrity, stale-data coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/timeline_transition_fixture_test.exs`
- `test/support/validation/timeline_transition_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted timeline transition-application fixture module directly
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
Validation timeline preservation fixture extraction published as `e1a72162`:
the focused module passed 6/6, the parent passed 115/115, and all twelve
Validation modules preserved the 181-test aggregate with no duplicate names.
Format, diff hygiene, dependency-closure checks, and bounded review were clean.

Next candidate:
Refresh the adjacent timeline transition-application fixture cluster in the
14,091-line parent. Select only a coherent multi-test boundary and move shared
builders to one support owner rather than copying them.

Blocked:
No.
