# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy-bundle authority fixture mapping.

Status:
Ready for next slice selection.

Selected slice:
No implementation selected yet. The next bounded candidate is to move only
`policy_bundle.operator_review_queue_authority` and
`policy_bundle.command_contact_authority` into the existing
`Validation.ReferenceFixtures.PolicyBundleArtifacts` leaf. Stop before
`policy_bundle.conservative_ops`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 9,216 lines. The
next two contiguous fixtures are the operator-review and command/contact
authority variants, totaling 148 facade lines. Both have dedicated assertions
in `policy_bundle_fixture_test.exs`.

Current coupling/problem:
Two authority-focused policy-bundle expectations remain in the general facade
even though the policy-bundle family now has a dedicated leaf. Moving this
pair extends that ownership without conflating the later operational-policy or
domain-authority groups.

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
The two selected authority fixtures exist only in the cohesive policy leaf,
all 21 fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the
same 195-entry map and deterministic term bytes, `conservative_ops` and the
complete facade remainder stay exact, focused and full validation tests pass,
and bounded review finds no blocker.

Verification gaps:
- Next candidate still requires a selection baseline before implementation.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected two-fixture map: deterministic digest
  `922b0b6e144d06303a9d45cc972d40754be0c36989f499e305fbf13a10fd3a2a`.
- Exact 193-entry remainder: deterministic digest
  `42ae1315da283c6e56026138ee125a6b55a3a13f469323ac41c0dcf69ca6de89`.
- Source boundary confirmed at facade lines 153-291, with
  `policy_bundle.operator_review_queue_authority` beginning at line 292 and no
  facade helper-attribute dependency in the selected literals.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  two-fixture digest, and 193-entry remainder digest all match the selection
  baseline exactly.
- Source partition proof: 21 maps total 195 entries, the new leaf owns exactly
  two fixtures, the facade owns 130, and all 210 pairwise intersections are
  empty.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused policy-bundle/facade validation: 18 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review: CLEAN. It confirmed both literals and the
  complete facade remainder are normalized-AST exact, the leaf owns only the
  selected keys, all 21 maps are unique and pairwise disjoint across 210
  intersections, all four digests and facade edge behaviors are unchanged,
  dependencies remain one-way, and it reproduced 18 focused and 181 full
  validation tests.

Behavior/schema changes:
None.

Outcome:
No authority-fixture implementation has started.

Last completed slice:
Base policy-bundle fixture extraction published as `c66cedc3`: the two exact
base/ground-network fixtures moved into a new 147-line leaf, the facade shrank
from 9,353 to 9,216 lines, the 195-entry map and all deterministic digests
stayed exact, 18 focused and 181 full validation tests passed, and bounded
review was clean.

Next candidate:
Select the two-fixture authority extraction described above, capture the exact
baseline and source partition, then stop before `policy_bundle.conservative_ops`.

Blocked:
No.
