# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy-bundle operational-variant mapping.

Status:
Publishing.

Selected slice:
Move only
`policy_bundle.conservative_ops` and
`policy_bundle.contact_command_review` into the existing
`Validation.ReferenceFixtures.PolicyBundleArtifacts` leaf. Stop before
`policy_bundle.degraded_payload_guard`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 9,068 lines. The
next two contiguous fixtures are conservative operations and contact-command
review variants, totaling 101 facade lines. Both participate in the focused
remaining-variant assertions in `policy_bundle_fixture_test.exs`.

Current coupling/problem:
Two operational-policy bundle expectations remain in the general facade
even though the policy-bundle family now has a dedicated leaf. Moving this
pair extends that ownership without conflating the following degraded/default
pair or later domain-authority group.

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
The two selected operational-policy fixtures exist only in the cohesive leaf,
all 21 fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the
same 195-entry map and deterministic term bytes, `degraded_payload_guard` and
the complete facade remainder stay exact, the prior four leaf fixtures remain
exact, focused and full validation tests pass, and bounded review finds no
blocker.

Verification gaps:
- None for this bounded slice.

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
The two exact operational-policy fixtures now live in the existing policy leaf
behind the unchanged facade. The facade shrank from 9,068 to 8,967 lines; the
leaf grew from four to six fixtures and from 295 to 396 lines.

Last completed slice:
Policy-bundle authority extraction published as `d3a4e305`: the two exact
operator-review/command-contact authority fixtures moved into the existing
leaf, the facade shrank from 9,216 to 9,068 lines, the leaf grew to four
fixtures, the 195-entry map and all deterministic digests stayed exact, 18
focused and 181 full validation tests passed, and bounded review was clean.

Next candidate:
Select the two-fixture operational-variant extraction described above, capture
the exact baseline and source partition, then stop before
`policy_bundle.degraded_payload_guard`.

Blocked:
No.
