# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Quality-gate fixture mapping.

Status:
Ready for implementation.

Selected slice:
Move
`quality_gate_report.v1` and the six `operational_quality_gate_*` summaries
from their contiguous facade range into a new
`Validation.ReferenceFixtures.QualityGateArtifacts` leaf. Preserve the
following stale station-calendar fixture exactly.

Why this slice:
`ReferenceFixtures` remains the largest production module at 1,861 lines. The
seven fixtures occupy 623 facade lines and exactly own
`quality_gate_fixture_test.exs`.

Current coupling/problem:
Quality-gate report, summary, import readiness, unavailable-resource,
resource-projection, operator-training, and schema-validation expectations form
one contiguous test-owned workflow but remain embedded in the general
registry. Moving all seven preserves the complete gate responsibility.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.QualityGateArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/quality_gate_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused quality-gate and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
All seven quality-gate fixtures exist only in the new cohesive leaf, all 46
fixture maps remain disjoint, `all/0` and `fetch/1` return exactly
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
- Selected seven-fixture map: deterministic digest
  `b89ef2c2eb4cfe803380c04fd88bd18fe3d3942a418fcf50a88f58d45a255e48`.
- Exact 188-entry remainder: deterministic digest
  `822cc2811e63e52ad41bc7baa2cee194a3a426ba54089073af9fc83c22a27b0f`.
- Contiguous source boundary confirmed at facade lines 287-909, followed by
  `station_calendar_report.stale_provider_reservation_hold`, with no facade
  helper-attribute dependency in the selected literals.
- Focused quality-gate/facade selection baseline: 20 tests passed.

Behavior/schema changes:
None.

Outcome:
No quality-gate implementation has started.

Last completed slice:
Operational-readiness extraction published as `848499d8`: the exact
five-fixture family moved into a new 463-line leaf, the facade shrank from 2,314
to 1,861 lines, the 195-entry map and all deterministic digests stayed exact,
17 focused and 181 full validation tests passed, and bounded review was clean.

Next candidate:
Select the quality-gate extraction described above, capture the
exact map and contiguous source boundary, then move the complete test-owned
family.

Blocked:
No.
