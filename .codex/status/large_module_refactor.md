# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema-compatibility fixture mapping.

Status:
Publishing.

Selected slice:
Move
`schema_validation_report.v1`, `schema_validation_batch_report.v1`,
`schema_migration_report.deprecated_campaign_plan`, and
`schema_migration_report.future_campaign_plan` from their contiguous facade
range into a new
`Validation.ReferenceFixtures.SchemaCompatibilityArtifacts` leaf. Preserve the
following resource-pressure Cadence manifest exactly.

Why this slice:
`ReferenceFixtures` remains the largest production module at 2,859 lines. The
four fixtures occupy 230 facade lines and exactly own
`schema_compatibility_fixture_test.exs`.

Current coupling/problem:
Schema validation, batch validation, deprecated migration, and future-version
migration expectations form one contiguous test-owned family but remain
embedded in the general registry. Moving all four preserves compatibility
responsibility without absorbing the following resource-pressure workflow.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.SchemaCompatibilityArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/schema_compatibility_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused schema-compatibility and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
All four schema-compatibility fixtures exist only in the new cohesive leaf, all
43 fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the same
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
- Selected four-fixture map: deterministic digest
  `6d64c5e86b9a157a00310df6a0c4926b4c4f886d900dee1b9254e38adc89fc12`.
- Exact 191-entry remainder: deterministic digest
  `b3ec590453d5539dd52b02831b4440a9ccaf2d55607ad46cf7de1a81c9060402`.
- Contiguous source boundary confirmed at facade lines 284-513, followed by
  `cadence_import_manifest.resource_pressure_v1`, with no facade
  helper-attribute dependency in the selected literals.
- Normalized-AST proof against selection commit `78628f31`: all four moved
  literals, the following resource-pressure manifest, and the complete 31-entry
  facade remainder are exact; the new leaf owns only the intended four keys.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  four-fixture digest, and exact 191-entry remainder digest all match their
  selection baselines.
- Source partition proof: 43 maps total 195 entries, the new leaf owns four, the
  facade owns 31, all 903 pairwise intersections are empty, and the source key
  union exactly matches the runtime map.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused schema-compatibility/facade validation: 16 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review against selection commit `78628f31` was clean:
  the contiguous source range and complete facade remainder are normalized-AST
  exact, all runtime and partition invariants reproduced, dependency direction
  remains one-way, and focused/full tests and hygiene gates passed.

Behavior/schema changes:
None.

Outcome:
The exact four-fixture schema-compatibility family now lives in a new cohesive
leaf behind the unchanged facade. The facade shrank from 2,859 to 2,631 lines;
the new leaf is 238 lines and owns exactly four fixtures.

Last completed slice:
Benchmark extraction published as `fd3042d3`: the exact eight-fixture family
moved into a new 426-line leaf, the facade shrank from 3,275 to 2,859 lines, the
195-entry map and all deterministic digests stayed exact, 13 focused and 181
full validation tests passed, and bounded review was clean.

Next candidate:
Select the schema-compatibility extraction described above, capture the exact
map and contiguous source boundary, then move the complete test-owned family.

Blocked:
No.
