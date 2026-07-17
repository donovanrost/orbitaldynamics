# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operational-readiness fixture mapping.

Status:
Ready for implementation.

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
- Implementation and post-move verification pending.

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
- Focused operational-readiness/facade selection baseline: 17 tests passed.

Behavior/schema changes:
None.

Outcome:
No operational-readiness implementation has started.

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
