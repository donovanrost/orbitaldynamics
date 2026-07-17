# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-activity-state fixture mapping.

Status:
Ready for implementation.

Selected slice:
Move
`timeline_activity_lifecycle_state.v1`, `timeline_activity_status_state.v1`,
`timeline_activity_approval_state.v1`, `timeline_lifecycle_state_summary.v1`,
`timeline_activity_state.v1`, and
`timeline_activity_precondition_summary.v1` from their two facade ranges into a
new `Validation.ReferenceFixtures.TimelineActivityStateArtifacts` leaf.
Preserve the intervening timeline-preservation family and following timeline
integrity report exactly.

Why this slice:
`ReferenceFixtures` remains the largest production module at 6,845 lines. The
six fixtures occupy 469 facade lines and exactly own
`timeline_activity_state_fixture_test.exs`.

Current coupling/problem:
Lifecycle, status, approval, aggregate-state, and precondition expectations are
split around the separate timeline-preservation family. Moving both complete
ranges preserves the focused-test responsibility without absorbing unrelated
preservation behavior.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.TimelineActivityStateArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/timeline_activity_state_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused timeline-activity-state and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The six timeline-activity-state fixtures exist only in the new cohesive leaf,
all 31 fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the same
195-entry map and deterministic term bytes, both following boundary fixtures
and the complete facade remainder stay exact, focused and full validation tests
pass, and bounded review finds no blocker.

Verification gaps:
- Implementation and post-move verification pending.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected six-fixture map: deterministic digest
  `90ce066371499bb4da6c122848e3964e324eeeba6f01607129670864dd25291e`.
- Exact 189-entry remainder: deterministic digest
  `a8191522d6d577e14dfda8fe6798bd0b9503b343634f26cb1c9db8cd43103992`.
- Source boundaries confirmed at facade lines 212-546 and 727-860, with the
  timeline-preservation family between them and the timeline-integrity report
  following them; the selected literals have no facade helper-attribute
  dependency.
- Focused timeline-activity-state/facade selection baseline: 18 tests passed.

Behavior/schema changes:
None.

Outcome:
No timeline-activity-state implementation has started.

Last completed slice:
Operational-planning extraction published as `7999a542`: the exact
three-fixture family moved into a new 287-line leaf, the facade shrank from
7,122 to 6,845 lines, the 195-entry map and all deterministic digests stayed
exact, 15 focused and 181 full validation tests passed, and bounded review was
clean.

Next candidate:
Select the timeline-activity-state extraction described above, capture the exact
combined map and both source-range boundaries, then move the complete
test-owned family together.

Blocked:
No.
