# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation timeline handoff fixture test-family extraction.

Status:
Selected.

Selected slice:
Move the three contiguous timeline-diff report, timeline-feedback report, and
Cadence-import manifest fixture tests into a focused module with one shared
builder owner.

Why this slice:
After the timeline transition split, `validation_test.exs` is 13,682 lines.
Tests 6,476-6,794 form a coherent timeline-to-Cadence handoff family and end
before resource-pressure fixtures. Their six observation/raw builders form one
closure; only observation builders remain needed by the deterministic
aggregate.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact timeline diff,
feedback, import-boundary, stale-data coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/timeline_handoff_fixture_test.exs`
- `test/support/validation/timeline_handoff_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted timeline handoff fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All three tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Validation timeline transition-application fixture extraction published as
`b777cc7c`: the focused module passed 4/4, the parent passed 111/111, and all
thirteen Validation modules preserved the 181-test aggregate with no duplicate
names. Format, diff hygiene, dependency-closure checks, and bounded review were
clean.

Next candidate:
Refresh the adjacent timeline diff/feedback and Cadence-import fixture cluster
in the 13,682-line parent. Select only a coherent multi-test boundary and move
shared builders to one support owner rather than copying them.

Blocked:
No.
