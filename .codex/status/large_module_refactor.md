# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Resource-safety fixture mapping.

Status:
Ready for implementation.

Selected slice:
Move
`cadence_import_manifest.resource_projection_battery_handoff_v1`,
`resource_projection_report.battery_handoff_v1`,
`resource_projection_report.stale_resource_summary_margins`,
`resource_filter_report.stale_resource_summary_margins`, and
`operator_review_package.resource_projection_battery_handoff_v1` from their
three facade ranges into a new
`Validation.ReferenceFixtures.ResourceSafetyArtifacts` leaf. Preserve each
following boundary fixture exactly.

Why this slice:
`ReferenceFixtures` remains the largest production module at 4,030 lines. The
five fixtures occupy 232 facade lines and together own
`resource_safety_fixture_test.exs`.

Current coupling/problem:
Cadence handoff, battery/stale projection, stale resource-filter, and
operator-review handoff expectations are separated across the facade despite
forming one focused safety workflow. Moving all five avoids another
partial-family extraction.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.ResourceSafetyArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/resource_safety_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused resource-safety and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The five resource-safety fixtures exist only in the new cohesive leaf, all 39
fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the same
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
- Selected five-fixture map: deterministic digest
  `94ac1bfe2aac2bef4bcf9ccd70c684aa1cc0f4d4f1ddb004c7e8773fb24beb0e`.
- Exact 190-entry remainder: deterministic digest
  `1ccbced5cf69920a0f8485ce2bf76cd4afcbbefe9db7dc2a0d061bc391d74028`.
- Source boundaries confirmed at facade lines 171-312, 621-668, and
  2051-2092, followed by `resource_summary.v1`,
  `objective_satisfaction_report.v1`, and
  `operational_execution_boundary_summary.v1`, respectively; the selected
  literals have no facade helper-attribute dependency.
- Focused resource-safety/facade selection baseline: 14 tests passed.

Behavior/schema changes:
None.

Outcome:
No resource-safety implementation has started.

Last completed slice:
Resource-projection extraction published as `6df16890`: the exact two-fixture
family moved into a new 138-line leaf, the facade shrank from 4,158 to 4,030
lines, the 195-entry map and all deterministic digests stayed exact, 14 focused
and 181 full validation tests passed, and bounded review was clean.

Next candidate:
Select the resource-safety extraction described above, capture the exact map
and three source boundaries, then move the complete test-owned family.

Blocked:
No.
