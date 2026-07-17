# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-transition fixture mapping.

Status:
Ready for implementation.

Selected slice:
Move
`timeline_transition_application_summary.v1`,
`timeline_transition_application_selected_integrity_summary.v1`,
`timeline_transition_application_report.v1`, and
`timeline_transition_application_selected_integrity.v1` from their contiguous
facade range into a new
`Validation.ReferenceFixtures.TimelineTransitionArtifacts` leaf. Preserve the
following contact-allocation report exactly.

Why this slice:
`ReferenceFixtures` remains the largest production module at 5,827 lines. The
four fixtures occupy 403 facade lines and exactly own
`timeline_transition_fixture_test.exs`.

Current coupling/problem:
Transition summaries, reports, and selected-integrity expectations now form one
contiguous facade family but remain embedded in the general registry. Moving
the whole test-owned range preserves its application/integrity proof as one
responsibility.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.TimelineTransitionArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/timeline_transition_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused timeline-transition and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The four timeline-transition fixtures exist only in the new cohesive leaf, all
33 fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the same
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
- Selected four-fixture map: deterministic digest
  `c82115f7a3875c01d2dcbaa3ecdc076a3a0f35a55ca9f2683136a138f6e1b3ac`.
- Exact 191-entry remainder: deterministic digest
  `fb9eea036860f5b5b25bfeb52834852c9bc65bde6475bf112eb9647eb2b37228`.
- Contiguous source boundary confirmed at facade lines 214-616, followed by
  `contact_allocation_report.v1`, with no facade helper-attribute dependency in
  the selected literals.
- Focused timeline-transition/facade selection baseline: 16 tests passed.

Behavior/schema changes:
None.

Outcome:
No timeline-transition implementation has started.

Last completed slice:
Timeline-preservation extraction published as `975edb84`: the exact six-fixture
family moved into a new 561-line leaf, the facade shrank from 6,378 to 5,827
lines, the 195-entry map and all deterministic digests stayed exact, 18 focused
and 181 full validation tests passed, and bounded review was clean.

Next candidate:
Select the timeline-transition extraction described above, capture the exact
combined map and contiguous source boundary, then move the complete test-owned
family together.

Blocked:
No.
