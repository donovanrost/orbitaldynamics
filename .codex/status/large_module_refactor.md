# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Resource-safety fixture mapping.

Status:
Ready for next slice selection.

Selected slice:
No implementation selected yet. The next bounded candidate is to move
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
- Next candidate still requires a selection baseline before implementation.

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
- Normalized-AST proof against selection commit `69f390f0`: both moved literals,
  the following battery-handoff fixture, and the complete 57-entry facade
  remainder are exact; the new leaf owns only the intended two keys.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  two-fixture digest, and exact 193-entry remainder digest all match their
  selection baselines.
- Source partition proof: 38 maps total 195 entries, the new leaf owns two, the
  facade owns 57, all 703 pairwise intersections are empty, and the source key
  union exactly matches the runtime map.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused resource-projection/facade validation: 14 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review against selection commit `69f390f0` was clean:
  the contiguous source range and complete facade remainder are normalized-AST
  exact, all runtime and partition invariants reproduced, dependency direction
  remains one-way, and focused/full tests and hygiene gates passed.

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
