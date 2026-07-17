# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy-bundle operational-variant mapping.

Status:
Ready for next slice selection.

Selected slice:
No implementation selected yet. The next bounded candidate is to move only
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
- Next candidate still requires a selection baseline before implementation.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected two-fixture map: deterministic digest
  `bdb6bbadc2eac861823a5789fd1e7c924629f832db664b88e7a0642e2d65f71b`.
- Exact 193-entry remainder: deterministic digest
  `a6a77486ed81152ecf20ff48d07a6e00161d093c7cbd9dc7ca2c062f206239ed`.
- Existing two-fixture policy leaf: deterministic digest
  `922b0b6e144d06303a9d45cc972d40754be0c36989f499e305fbf13a10fd3a2a`.
- Source boundary confirmed at facade lines 154-301, with
  `policy_bundle.conservative_ops` beginning at line 302 and no facade
  helper-attribute dependency in the selected literals.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  authority-pair digest, prior base-pair digest, and exact 193-entry remainder
  digest all match their selection baselines. The resulting four-fixture leaf
  digest is
  `f12188bdae7efa82b99ba627007b3844de96c858c14ba919d0c6519cbf4b348f`.
- Source partition proof: 21 maps total 195 entries, the policy leaf owns four,
  the facade owns 128, and all 210 pairwise intersections are empty.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused policy-bundle/facade validation: 18 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review: CLEAN. It confirmed the authority pair moved
  unchanged, the prior two leaf fixtures and complete facade remainder are
  normalized-AST exact, the leaf owns only four intended keys, all 21 maps are
  unique and pairwise disjoint, all six digests and facade edge behaviors are
  unchanged, dependencies remain one-way, and it reproduced 18 focused and 181
  full validation tests.

Behavior/schema changes:
None.

Outcome:
No operational-variant implementation has started.

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
