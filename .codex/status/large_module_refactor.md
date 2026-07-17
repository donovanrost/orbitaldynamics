# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-handoff fixture mapping.

Status:
Ready for implementation.

Selected slice:
Move
`timeline_diff_report.v1`, `cadence_import_manifest.v1`, and
`timeline_feedback_report.v1` from their two facade ranges into a new
`Validation.ReferenceFixtures.TimelineHandoffArtifacts` leaf. Preserve the
following resource-handoff manifest and contact-allocation report exactly.

Why this slice:
`ReferenceFixtures` remains the largest production module at 7,437 lines. The
three fixtures total 317 lines and exactly own
`timeline_handoff_fixture_test.exs`.

Current coupling/problem:
Timeline diff, feedback, and Cadence import handoff expectations are separated
by unrelated facade families despite sharing one focused handoff workflow.
Moving all three preserves the test-owned responsibility rather than creating
partial or one-fixture leaves.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.TimelineHandoffArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/timeline_handoff_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused timeline-handoff and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The three timeline-handoff fixtures exist only in the new cohesive leaf, all 29
fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the same
195-entry map and deterministic term bytes, both following boundary fixtures
and the complete facade remainder stay exact, focused and full validation
tests pass, and bounded review finds no blocker.

Verification gaps:
- Implementation, verification, and bounded review pending.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected three-fixture map: deterministic digest
  `8e44976106d5c32da69a6f017448fa9a635e069f348b82a5880548ee0039631e`.
- Exact 192-entry remainder: deterministic digest
  `ca8dadbc94fd2f07030dac7ba394ed9dcd089d42eebf60f81c0b0fec7f9c633e`.
- Source boundaries confirmed at facade lines 161-373 and 2127-2230, followed
  by the resource-handoff manifest and contact-allocation report, respectively,
  with no facade helper-attribute dependency in the selected literals.
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Outcome:
No timeline-handoff implementation has started.

Last completed slice:
Policy-evidence extraction published as `86000b54`: the exact four-fixture
family moved into a new 157-line leaf, the facade shrank from 7,584 to 7,437
lines, the 195-entry map and all deterministic digests stayed exact, 16 focused
and 181 full validation tests passed, and bounded review was clean.

Next candidate:
Select the timeline-handoff extraction described above, capture the exact
combined map and both source-range boundaries, then move the complete
test-owned family together.

Blocked:
No.
