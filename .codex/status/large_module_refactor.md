# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Objective-scoring fixture mapping.

Status:
Ready for next slice selection.

Selected slice:
No implementation selected yet. The next bounded candidate is to move
`objective_satisfaction_report.v1`, `objective_tradeoff_report.v1`,
`score_term_report.v1`, and `ranking_comparison_report.v1` from their
contiguous facade range into a new
`Validation.ReferenceFixtures.ObjectiveScoringArtifacts` leaf. Preserve the
following strategy-branch fixture exactly.

Why this slice:
`ReferenceFixtures` remains the largest production module at 3,603 lines. The
four fixtures occupy 226 facade lines and exactly own
`objective_scoring_fixture_test.exs`.

Current coupling/problem:
Objective satisfaction, tradeoff, score-term, and ranking expectations form one
contiguous test-owned family but remain embedded in the general registry.
Moving all four preserves scoring responsibility without absorbing strategy
artifacts.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.ObjectiveScoringArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/objective_scoring_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused objective-scoring and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The four objective-scoring fixtures exist only in the new cohesive leaf, all 41
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
- Selected three-fixture map: deterministic digest
  `0718ed567b5ca451301eba883659836cde6ad4299ec8f32ac53f11ede66a9b49`.
- Exact 192-entry remainder: deterministic digest
  `b366a6ab25108ca049895e9c955d3a2f66fab05c5174640c0d62683c8f9c141c`.
- Source boundaries confirmed at facade lines 172-233 and 343-479, with the
  station-calendar fixtures between them and
  `objective_satisfaction_report.v1` following them; the selected literals have
  no facade helper-attribute dependency.
- Normalized-AST proof against selection commit `37c2b0fe`: all three moved
  literals, both intervening station-calendar fixtures, the following
  objective-satisfaction report, and the complete 49-entry facade remainder are
  exact; the new leaf owns only the intended three keys.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  three-fixture digest, and exact 192-entry remainder digest all match their
  selection baselines.
- Source partition proof: 40 maps total 195 entries, the new leaf owns three,
  the facade owns 49, all 780 pairwise intersections are empty, and the source
  key union exactly matches the runtime map.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused resource-summary/facade validation: 15 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review against selection commit `37c2b0fe` was clean:
  both source ranges and the complete facade remainder are normalized-AST
  exact, all runtime and partition invariants reproduced, dependency direction
  remains one-way, and focused/full tests and hygiene gates passed.

Behavior/schema changes:
None.

Outcome:
No objective-scoring implementation has started.

Last completed slice:
Resource-summary extraction published as `e97ed85b`: the exact three-fixture
family moved into a new 207-line leaf, the facade shrank from 3,800 to 3,603
lines, the 195-entry map and all deterministic digests stayed exact, 15 focused
and 181 full validation tests passed, and bounded review was clean.

Next candidate:
Select the objective-scoring extraction described above, capture the exact map
and contiguous source boundary, then move the complete test-owned family.

Blocked:
No.
