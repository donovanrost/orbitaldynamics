# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy-bundle fixture family mapping.

Status:
Ready for next slice selection.

Selected slice:
No implementation selected yet. The next bounded candidate is to move only
`policy_bundle.v1` and `policy_bundle.ground_network_allocation` into a new
`Validation.ReferenceFixtures.PolicyBundleArtifacts` leaf. Stop before
`policy_bundle.operator_review_queue_authority`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 9,353 lines. The
next two contiguous fixtures are the base policy bundle and its foundational
ground-network allocation specialization, totaling 139 facade lines. Both have
dedicated assertions in `policy_bundle_fixture_test.exs`.

Current coupling/problem:
Policy-bundle artifact expectations remain embedded in the general facade even
though they form a large, cohesive, independently tested family. Moving only
the first two establishes the family leaf without conflating the later
authority and operational-policy subfamilies.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.PolicyBundleArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/policy_bundle_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused policy-bundle and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The two selected policy-bundle fixtures exist only in the new cohesive leaf,
all 21 fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the
same 195-entry map and deterministic term bytes, the operator-review fixture
and complete facade remainder stay exact, focused and full validation tests
pass, and bounded review finds no blocker.

Verification gaps:
- Next candidate still requires a selection baseline before implementation.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Post-move exact proof: 195 entries with the same deterministic map and
  sorted-key digests; `CandidateStrategyArtifacts` owns four fixtures, the
  facade owns 132, all 20 fixture maps remain internally unique and pairwise
  disjoint, and facade `fetch/1` returns the moved fixture unchanged.
- Focused validation: 18 tests passed across
  `candidate_strategy_fixture_test.exs`, `core_policy_test.exs`, and
  `validation_test.exs`.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review: CLEAN. It confirmed the literal one-fixture move,
  exact normalized source union, all 20 maps internally unique and pairwise
  disjoint across 190 intersections, exact runtime digests, all 195 successful
  fetches, unchanged missing/nonbinary edge behavior, one-way dependencies, and
  reproduced the 18 focused and 181 full validation tests.

Behavior/schema changes:
None.

Outcome:
No policy-bundle implementation has started.

Last completed slice:
Proposed-contact ownership cleanup published as `ba7a7779`: the exact fixture
moved into the existing candidate-strategy leaf, the facade shrank from 9,397
to 9,353 lines, the 195-entry map and deterministic bytes stayed exact, 18
focused and 181 full validation tests passed, and bounded review was clean.

Next candidate:
Select the two-fixture base/ground-network policy-bundle extraction described
above, capture the exact baseline and source partition, then stop before the
operator-review authority fixture.

Blocked:
No.
