# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy-bundle domain-authority mapping.

Status:
Publishing.

Selected slice:
Move
`policy_bundle.maneuver_authority`,
`policy_bundle.resource_projection_authority`, and
`policy_bundle.timeline_protection` into the existing
`Validation.ReferenceFixtures.PolicyBundleArtifacts` leaf. Stop before
`policy_bundle.organization_adapter`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 8,860 lines. The
next three contiguous fixtures are the domain-authority variants, totaling 192
facade lines. The focused policy-bundle test asserts exactly this trio together.

Current coupling/problem:
The cohesive domain-authority policy expectations remain in the general facade
even though the policy-bundle family now has a dedicated leaf. Moving the trio
keeps its test-owned boundary intact and stops before the distinct organization
adapter.

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
The three selected domain-authority fixtures exist only in the policy leaf,
all 21 fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the
same 195-entry map and deterministic term bytes, `organization_adapter` and the
complete facade remainder stay exact, the prior eight leaf fixtures remain
exact, focused and full validation tests pass, and bounded review finds no
blocker.

Verification gaps:
- None for this bounded slice.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected three-fixture map: deterministic digest
  `9ba63587e83807bf27fb8476e6e123fae5204202834a57c467903dadbdd5ce53`.
- Exact 192-entry remainder: deterministic digest
  `1bccf186eb7c2481e2fcbdddffc5e0854d99da98b10fbef20945e67bab374cd2`.
- Existing eight-fixture policy leaf: deterministic digest
  `52dd813392fb09ac5a16bdc6aa2cb13404f38add14481ac2852122ae380c3a00`.
- Source boundary confirmed at facade lines 154-345, with
  `policy_bundle.organization_adapter` beginning at line 346 and no facade
  helper-attribute dependency in the selected literals.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  domain-authority digest, prior eight-fixture leaf digest, and exact 192-entry
  remainder digest all match their selection baselines. The resulting
  eleven-fixture leaf digest is
  `ba5aa4182753941be877a6973bc2e5162ef43604e6ecda753d7904a0a9f1769a`.
- Source partition proof: 21 maps total 195 entries, the policy leaf owns
  eleven, the facade owns 121, and all 210 pairwise intersections are empty.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused policy-bundle/facade validation: 18 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review: CLEAN. It confirmed the domain-authority trio
  moved unchanged, the prior eight leaf fixtures and complete facade remainder
  are normalized-AST exact, the leaf owns only eleven intended keys, all 21
  maps are unique and pairwise disjoint, all six digests and facade edge
  behaviors are unchanged, dependencies remain one-way, and it reproduced 18
  focused and 181 full validation tests.

Behavior/schema changes:
None.

Outcome:
The exact domain-authority trio now lives in the existing policy leaf behind
the unchanged facade. The facade shrank from 8,860 to 8,668 lines; the leaf
grew from eight to eleven fixtures and from 503 to 695 lines.

Last completed slice:
Policy-bundle degraded/default extraction published as `ae587409`: the exact
pair moved into the existing leaf, the facade shrank from 8,967 to 8,860 lines,
the leaf grew to eight fixtures, the 195-entry map and all deterministic
digests stayed exact, 18 focused and 181 full validation tests passed, and
bounded review was clean.

Next candidate:
Select the domain-authority extraction described above, capture the exact
baseline and source partition, then stop before
`policy_bundle.organization_adapter`.

Blocked:
No.
