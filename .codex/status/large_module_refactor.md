# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Resource-pressure handoff fixture mapping.

Status:
Ready for implementation.

Selected slice:
Move
`cadence_import_manifest.resource_pressure_v1`,
`operational_readiness_report.resource_pressure_v1`,
`operator_review_package.resource_pressure_v1`, and
`quality_gate_report.resource_pressure_v1` from their contiguous facade range
into a new
`Validation.ReferenceFixtures.ResourcePressureHandoffArtifacts` leaf. Preserve
the following general operator-review package exactly.

Why this slice:
`ReferenceFixtures` remains the largest production module at 2,631 lines. The
four fixtures occupy 319 facade lines and together own
`resource_pressure_handoff_fixture_test.exs`.

Current coupling/problem:
Cadence import, operational readiness, operator review, and quality-gate
resource-pressure expectations form one contiguous test-owned handoff family
but remain embedded in the general registry. Moving all four preserves the
complete cross-artifact workflow.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.ResourcePressureHandoffArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/resource_pressure_handoff_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused resource-pressure-handoff and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
All four resource-pressure handoff fixtures exist only in the new cohesive
leaf, all 44 fixture maps remain disjoint, `all/0` and `fetch/1` return exactly
the same 195-entry map and deterministic term bytes, both following boundary fixtures
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
  `dc8f18a58380de10149df14c2b91072806b2aa2d7a19545f9260d43306451724`.
- Exact 191-entry remainder: deterministic digest
  `af314ed742420bd93c44cc90cc25c7e60f212e98ecd139074e8e02f59b85cbaa`.
- Contiguous source boundary confirmed at facade lines 285-603, followed by
  `operator_review_package.v1`, with no facade helper-attribute dependency in
  the selected literals.
- Focused resource-pressure-handoff/facade selection baseline: 13 tests passed.

Behavior/schema changes:
None.

Outcome:
No resource-pressure handoff implementation has started.

Last completed slice:
Schema-compatibility extraction published as `2320389d`: the exact four-fixture
family moved into a new 238-line leaf, the facade shrank from 2,859 to 2,631
lines, the 195-entry map and all deterministic digests stayed exact, 16 focused
and 181 full validation tests passed, and bounded review was clean.

Next candidate:
Select the resource-pressure handoff extraction described above, capture the
exact map and contiguous source boundary, then move the complete test-owned
family.

Blocked:
No.
