# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation timeline handoff fixture test-family extraction.

Status:
Published as `92467b94`.

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
Three byte-identical timeline handoff family tests moved into a 334-line
focused module. Six observation/raw builders now have one 38-line shared
support owner; the parent imports only the three aggregate observation
builders, with no private residue. The parent fell from 13,682 to 13,343 lines.
Total test/support/loader LOC grew by 34 lines for explicit ownership without
helper duplication. All 181 Validation test names remain unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation timeline handoff fixture extraction published as `92467b94`: the
focused module passed 3/3, the parent passed 108/108, and all fourteen
Validation modules preserved the 181-test aggregate with no duplicate names.
Format, diff hygiene, dependency-closure checks, and bounded review were clean.

Next candidate:
Refresh the adjacent resource-pressure, command-window, constraint, and
operational-timeline fixture cluster in the 13,343-line parent. Select only a
coherent multi-test boundary and move shared builders to one support owner
rather than copying them.

Blocked:
No.
