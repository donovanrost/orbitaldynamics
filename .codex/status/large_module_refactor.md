# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operational-readiness fixture mapping.

Status:
Publishing.

Selected slice:
Move
`operator_review_package.v1`, `operational_execution_boundary_summary.v1`,
`operational_import_eligibility_summary.v1`, `operational_readiness_report.v1`,
and `operational_readiness_gate_summary.v1` from their contiguous facade range
into a new `Validation.ReferenceFixtures.OperationalReadinessArtifacts` leaf.
Preserve the following quality-gate report exactly.

Why this slice:
`ReferenceFixtures` remains the largest production module at 2,314 lines. The
five fixtures occupy 455 facade lines and exactly own
`operational_readiness_fixture_test.exs`.

Current coupling/problem:
Operator review, execution boundary, import eligibility, readiness reporting,
and readiness-gate expectations form one contiguous test-owned workflow but
remain embedded in the general registry. Moving all five preserves the complete
readiness responsibility without absorbing quality-gate detail.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.OperationalReadinessArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/operational_readiness_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused operational-readiness and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
All five operational-readiness fixtures exist only in the new cohesive leaf,
all 45 fixture maps remain disjoint, `all/0` and `fetch/1` return exactly
the same 195-entry map and deterministic term bytes, both following boundary fixtures
and the complete facade remainder stay exact, focused and full validation tests
pass, and bounded review finds no blocker.

Verification gaps:
- None for this slice.

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
The exact five-fixture operational-readiness family now lives in a new cohesive
leaf behind the unchanged facade. The facade shrank from 2,314 to 1,861 lines;
the new leaf is 463 lines and owns exactly five fixtures.

Last completed slice:
Resource-pressure handoff extraction published as `025a3b83`: the exact
four-fixture family moved into a new 327-line leaf, the facade shrank from 2,631
to 2,314 lines, the 195-entry map and all deterministic digests stayed exact,
13 focused and 181 full validation tests passed, and bounded review was clean.

Next candidate:
Select the operational-readiness extraction described above, capture the
exact map and contiguous source boundary, then move the complete test-owned
family.

Blocked:
No.
