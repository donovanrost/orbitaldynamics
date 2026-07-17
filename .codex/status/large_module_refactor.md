# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy-bundle degraded/default variant mapping.

Status:
Ready for next slice selection.

Selected slice:
No implementation selected yet. The next bounded candidate is to move only
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
- Next candidate still requires a selection baseline before implementation.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected two-fixture map: deterministic digest
  `fe4946a1979e1d15c2dce3ad67ffeebc91990b54f737dc23a0ef9aa6ba68239b`.
- Exact 193-entry remainder: deterministic digest
  `b293c111fe76fa0ef24b978b09c43ab9309e2b76ac9ee0203b16e8bfc9cfc94d`.
- Existing four-fixture policy leaf: deterministic digest
  `f12188bdae7efa82b99ba627007b3844de96c858c14ba919d0c6519cbf4b348f`.
- Source boundary confirmed at facade lines 154-254, with
  `policy_bundle.degraded_payload_guard` beginning at line 255 and no facade
  helper-attribute dependency in the selected literals.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  operational-pair digest, prior four-fixture leaf digest, and exact 193-entry
  remainder digest all match their selection baselines. The resulting
  six-fixture leaf digest is
  `919b9027996552173ee3474e0522e39fe947fd912c09f892474dc0137bf093c1`.
- Source partition proof: 21 maps total 195 entries, the policy leaf owns six,
  the facade owns 126, and all 210 pairwise intersections are empty.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused policy-bundle/facade validation: 18 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review: CLEAN. It confirmed the operational pair moved
  unchanged, the prior four leaf fixtures and complete facade remainder are
  normalized-AST exact, the leaf owns only six intended keys, all 21 maps are
  unique and pairwise disjoint, all six digests and facade edge behaviors are
  unchanged, dependencies remain one-way, and it reproduced 18 focused and 181
  full validation tests.

Behavior/schema changes:
None.

Outcome:
No degraded/default implementation has started.

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
