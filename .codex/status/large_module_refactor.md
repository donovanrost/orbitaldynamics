# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-preservation fixture mapping.

Status:
Publishing.

Selected slice:
Move
`timeline_preservation_report.v1`, `timeline_preservation_status.v1`,
`timeline_integrity_report.v1`, `timeline_dependency_impact_summary.v1`,
`timeline_diff_summary.v1`, and `timeline_publication_summary.v1` from their
now-contiguous facade range into a new
`Validation.ReferenceFixtures.TimelinePreservationArtifacts` leaf. Preserve
the following timeline transition-application summary exactly.

Why this slice:
`ReferenceFixtures` remains the largest production module at 6,378 lines. The
six fixtures occupy 553 facade lines and exactly own
`timeline_preservation_fixture_test.exs`.

Current coupling/problem:
Preservation, integrity, dependency impact, diff, and publication expectations
now form one contiguous facade family but remain embedded in the general
registry. Moving the whole test-owned range avoids splitting its lifecycle
proof across multiple fixture modules.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.TimelinePreservationArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/timeline_preservation_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused timeline-preservation and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The six timeline-preservation fixtures exist only in the new cohesive leaf, all
32 fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the same
195-entry map and deterministic term bytes, both following boundary fixtures
and the complete facade remainder stay exact, focused and full validation tests
pass, and bounded review finds no blocker.

Verification gaps:
- None for this slice.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected six-fixture map: deterministic digest
  `ae9515517c9335563d82792892c9549a5f3a8b46e2d806bba5355b688f50995f`.
- Exact 189-entry remainder: deterministic digest
  `ff9fa47cdb8295f6737e5bf87e80b6d8605b31f7af7ff1c9f693014763756a3e`.
- Contiguous source boundary confirmed at facade lines 213-765, followed by
  `timeline_transition_application_summary.v1`, with no facade
  helper-attribute dependency in the selected literals.
- Normalized-AST proof against selection commit `d59fc2e5`: all six moved
  literals, the following transition-application summary, and the complete
  79-entry facade remainder are exact; the new leaf owns only the intended six
  keys.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  six-fixture digest, and exact 189-entry remainder digest all match their
  selection baselines.
- Source partition proof: 32 maps total 195 entries, the new leaf owns six, the
  facade owns 79, all 496 pairwise intersections are empty, and the source key
  union exactly matches the runtime map.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused timeline-preservation/facade validation: 18 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review against selection commit `d59fc2e5` was clean:
  the contiguous source range and complete facade remainder are normalized-AST
  exact, all runtime and partition invariants reproduced, dependency direction
  remains one-way, and focused/full tests and hygiene gates passed.

Behavior/schema changes:
None.

Outcome:
The exact six-fixture timeline-preservation family now lives in a new cohesive
leaf behind the unchanged facade. The facade shrank from 6,378 to 5,827 lines;
the new leaf is 561 lines and owns exactly six fixtures.

Last completed slice:
Timeline-activity-state extraction published as `cdc53ba4`: the exact
six-fixture family moved into a new 477-line leaf, the facade shrank from 6,845
to 6,378 lines, the 195-entry map and all deterministic digests stayed exact,
18 focused and 181 full validation tests passed, and bounded review was clean.

Next candidate:
Select the timeline-preservation extraction described above, capture the exact
combined map and contiguous source boundary, then move the complete test-owned
family together.

Blocked:
No.
