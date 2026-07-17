# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Decision-support fixture mapping.

Status:
Ready for next slice selection.

Selected slice:
No implementation selected yet. The next bounded candidate is to move
`maneuver_review_report.v1`, `monte_carlo_reproducibility_report.v1`, and
`pareto_frontier_report.v1` from their contiguous facade range into a new
`Validation.ReferenceFixtures.DecisionSupportArtifacts` leaf. Preserve the
following resource-projection report exactly.

Why this slice:
`ReferenceFixtures` remains the largest production module at 4,307 lines. The
three fixtures occupy 151 facade lines and exactly own
`decision_support_fixture_test.exs`.

Current coupling/problem:
Maneuver review, reproducibility, and Pareto-frontier expectations form a
compact, contiguous test-owned family but remain embedded in the general
registry. Moving all three preserves the complete decision-support
responsibility without absorbing resource-projection behavior.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.DecisionSupportArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/decision_support_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused decision-support and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The three decision-support fixtures exist only in the new cohesive leaf, all 37
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
- Selected relay fixture map: deterministic digest
  `97e28bc97fe67e55c49ce4bdfdfe23b0dde4f9bc26b7470ab56533fd2f3fac16`.
- Existing two-fixture link-capacity leaf: deterministic digest
  `7817e0c1af0ec3b38d0c9ea5768aa301c34dce167c369342ffd5c38af2ae7c2d`;
  expected combined three-fixture digest
  `4219e88a9ccd588496edd156e2c839c1c1e876159590b2d1eab8348198148a8a`.
- Exact 194-entry remainder: deterministic digest
  `6bd87aeff9ffe9f98af1aab104a646697dbe92b75ca04b19e6011c700988f055`.
- Source boundary confirmed at facade lines 218-315, followed by
  `maneuver_review_report.v1`, with no facade helper-attribute dependency in
  the selected literal.
- Normalized-AST proof against selection commit `6365d042`: the moved relay
  literal, both existing link-capacity literals, the combined three-entry leaf,
  the following maneuver report, and the complete 62-entry facade remainder
  are exact.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected relay
  digest, combined three-fixture leaf digest, and exact 194-entry remainder
  digest all match their selection baselines.
- Source partition proof: 36 maps total 195 entries, the completed
  link-capacity leaf owns three, the facade owns 62, all 630 pairwise
  intersections are empty, and the source key union exactly matches the runtime
  map.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused link-capacity/facade validation: 15 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review against selection commit `6365d042` was clean:
  the moved and existing target literals, completed leaf, facade remainder, and
  boundary fixture are normalized-AST exact; all runtime, partition, focused,
  full-test, dependency, and hygiene checks reproduced.

Behavior/schema changes:
None.

Outcome:
No decision-support implementation has started.

Last completed slice:
Link-capacity ownership cleanup published as `ad07b74b`: the exact relay fixture
moved into the existing leaf, the facade shrank from 4,405 to 4,307 lines, the
leaf grew from 179 to 277 lines, the 195-entry map and all deterministic digests
stayed exact, 15 focused and 181 full validation tests passed, and bounded
review was clean.

Next candidate:
Select the decision-support extraction described above, capture the exact map
and contiguous source boundary, then move the complete test-owned family.

Blocked:
No.
