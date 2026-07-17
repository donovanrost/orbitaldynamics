# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy-bundle degraded/default variant mapping.

Status:
Publishing.

Selected slice:
Move only
`policy_bundle.degraded_payload_guard` and `policy_bundle.default` into the
existing `Validation.ReferenceFixtures.PolicyBundleArtifacts` leaf. Stop
before `policy_bundle.maneuver_authority`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 8,967 lines. The
next two contiguous fixtures are the degraded-payload guard and default policy
variants, totaling 107 facade lines. Both participate in the focused
remaining-variant assertions in `policy_bundle_fixture_test.exs`.

Current coupling/problem:
The remaining contiguous operational-policy expectations stay in the facade
even though the policy-bundle family now has a dedicated leaf. Moving this
pair completes that local variant group without conflating the following
domain-authority group.

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
The degraded/default fixtures exist only in the cohesive policy leaf,
all 21 fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the
same 195-entry map and deterministic term bytes, `maneuver_authority` and the
complete facade remainder stay exact, the prior six leaf fixtures remain exact,
focused and full validation tests pass, and bounded review finds no blocker.

Verification gaps:
- None for this bounded slice.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected two-fixture map: deterministic digest
  `299a094528a2254a2fd38f526fa4e14592ba94884cca39240932292b3d2a74e3`.
- Exact 193-entry remainder: deterministic digest
  `ec38c75b690ba17093781f4da3d764d46959a413e1a0665d317cbab006b411c9`.
- Existing six-fixture policy leaf: deterministic digest
  `919b9027996552173ee3474e0522e39fe947fd912c09f892474dc0137bf093c1`.
- Source boundary confirmed at facade lines 154-260, with
  `policy_bundle.maneuver_authority` beginning at line 261 and no facade
  helper-attribute dependency in the selected literals.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  degraded/default digest, prior six-fixture leaf digest, and exact 193-entry
  remainder digest all match their selection baselines. The resulting
  eight-fixture leaf digest is
  `52dd813392fb09ac5a16bdc6aa2cb13404f38add14481ac2852122ae380c3a00`.
- Source partition proof: 21 maps total 195 entries, the policy leaf owns eight,
  the facade owns 124, and all 210 pairwise intersections are empty.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused policy-bundle/facade validation: 18 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review: CLEAN. It confirmed the degraded/default pair
  moved unchanged, the prior six leaf fixtures and complete facade remainder
  are normalized-AST exact, the leaf owns only eight intended keys, all 21 maps
  are unique and pairwise disjoint, all six digests and facade edge behaviors
  are unchanged, dependencies remain one-way, and it reproduced 18 focused and
  181 full validation tests.

Behavior/schema changes:
None.

Outcome:
The exact degraded/default fixtures now live in the existing policy leaf behind
the unchanged facade. The facade shrank from 8,967 to 8,860 lines; the leaf
grew from six to eight fixtures and from 396 to 503 lines.

Last completed slice:
Policy-bundle operational extraction published as `f5227ca0`: the exact
conservative/contact-review fixtures moved into the existing leaf, the facade
shrank from 9,068 to 8,967 lines, the leaf grew to six fixtures, the 195-entry
map and all deterministic digests stayed exact, 18 focused and 181 full
validation tests passed, and bounded review was clean.

Next candidate:
Select the degraded/default extraction described above, capture the exact
baseline and source partition, then stop before
`policy_bundle.maneuver_authority`.

Blocked:
No.
