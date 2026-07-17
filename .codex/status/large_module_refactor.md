# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-handoff fixture mapping.

Status:
Ready for next slice selection.

Selected slice:
No implementation selected yet. The next bounded candidate is to move
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
- Next candidate still requires a selection baseline before implementation.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected four-fixture map: deterministic digest
  `8790ec2500573e3e85950af1f3283e67662c16ffbc09c4aae47cf0033cf70a97`.
- Exact 191-entry remainder: deterministic digest
  `9450be157ec65f56cfdbca6f1c678e0b56074a28b0d61136bb31c3bffb4b53c6`.
- Source boundary confirmed at facade lines 160-308, with
  `timeline_diff_report.v1` beginning at line 309 and no facade
  helper-attribute dependency in the selected literals.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  four-fixture digest, and exact 191-entry remainder digest all match their
  selection baselines.
- Source partition proof: 28 maps total 195 entries, the new leaf owns four, the
  facade owns 97, and all 378 pairwise intersections are empty.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused policy-evidence/facade validation: 16 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review: CLEAN. It confirmed all four policy-evidence
  fixtures moved unchanged, the timeline-diff boundary and complete facade
  remainder are normalized-AST exact, the new leaf owns only its four intended
  keys, all 28 maps are unique and pairwise disjoint, all digests and facade
  edge behaviors are unchanged, dependencies remain one-way, and it reproduced
  16 focused and 181 full validation tests.

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
