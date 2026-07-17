# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Quality-gate fixture mapping.

Status:
Ready for next slice selection.

Selected slice:
No implementation selected yet. The next bounded candidate is to move
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
- Next candidate still requires a selection baseline before implementation.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected five-fixture map: deterministic digest
  `75f5fda732e4dba224c4b1a8f0209e529eb32a4b93b4108f2587089781a35e02`.
- Exact 190-entry remainder: deterministic digest
  `da5dcce54b03be7f6658dcc2b01dd07afdbe2fc6c61d8a2624132a9dc94e57b6`.
- Contiguous source boundary confirmed at facade lines 286-740, followed by
  `quality_gate_report.v1`, with no facade helper-attribute dependency in the
  selected literals.
- Normalized-AST proof against selection commit `67702192`: all five moved
  literals, the following quality-gate report, and the complete 22-entry facade
  remainder are exact; the new leaf owns only the intended five keys.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  five-fixture digest, and exact 190-entry remainder digest all match their
  selection baselines.
- Source partition proof: 45 maps total 195 entries, the new leaf owns five, the
  facade owns 22, all 990 pairwise intersections are empty, and the source key
  union exactly matches the runtime map.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused operational-readiness/facade validation: 17 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review against selection commit `67702192` was clean:
  the contiguous source range and complete facade remainder are normalized-AST
  exact, all runtime and partition invariants reproduced, dependency direction
  remains one-way, and focused/full tests and hygiene gates passed.

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
