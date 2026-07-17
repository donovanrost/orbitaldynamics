# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Decision-support fixture mapping.

Status:
Ready for implementation.

Selected slice:
Move
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
- Implementation and post-move verification pending.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected three-fixture map: deterministic digest
  `8e685aacc64348e7a2750ce2030f2bad1afd105177b22e42a779b13ed5bbd6ea`.
- Exact 192-entry remainder: deterministic digest
  `7f0ffff7493c23fa4d26f99c297796a43008d34cc19c5632e36c0d92c35ccf6c`.
- Contiguous source boundary confirmed at facade lines 218-368, followed by
  `resource_projection_report.v1`, with no facade helper-attribute dependency
  in the selected literals.
- Focused decision-support/facade selection baseline: 15 tests passed.

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
