# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Resource-projection fixture mapping.

Status:
Ready for implementation.

Selected slice:
Move
`resource_projection_report.v1` and `resource_projection_flow_summary.v1` from
their contiguous facade range into a new
`Validation.ReferenceFixtures.ResourceProjectionArtifacts` leaf. Preserve the
following resource-projection battery-handoff fixture exactly.

Why this slice:
`ReferenceFixtures` remains the largest production module at 4,158 lines. The
two fixtures occupy 130 facade lines and exactly own
`resource_projection_fixture_test.exs`.

Current coupling/problem:
Resource-projection report and flow-summary expectations form a compact,
contiguous test-owned family but remain embedded in the general registry.
Moving both preserves projection behavior without absorbing the separate
battery-safety handoff family.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.ResourceProjectionArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/resource_projection_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused resource-projection and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The two resource-projection fixtures exist only in the new cohesive leaf, all 38
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
- Selected two-fixture map: deterministic digest
  `9d8ee8e4a8d9e63c7e2c85094c2362c70195d50dbfb42e8a9702d076ee4cdab6`.
- Exact 193-entry remainder: deterministic digest
  `6659c79132cd96d163d53517a3a284a8ab38c4d8a1f8c13b9f4f90bdd29a9551`.
- Contiguous source boundary confirmed at facade lines 219-348, followed by
  `resource_projection_report.battery_handoff_v1`, with no facade
  helper-attribute dependency in the selected literals.
- Focused resource-projection/facade selection baseline: 14 tests passed.

Behavior/schema changes:
None.

Outcome:
No resource-projection implementation has started.

Last completed slice:
Decision-support extraction published as `59550414`: the exact three-fixture
family moved into a new 159-line leaf, the facade shrank from 4,307 to 4,158
lines, the 195-entry map and all deterministic digests stayed exact, 15 focused
and 181 full validation tests passed, and bounded review was clean.

Next candidate:
Select the resource-projection extraction described above, capture the exact map
and contiguous source boundary, then move the complete test-owned family.

Blocked:
No.
