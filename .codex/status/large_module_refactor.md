# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy-decision reference-fixture extraction.

Status:
Publishing implementation.

Selected slice:
Move the contiguous approval-requirement and policy-decision fixtures into
`Validation.ReferenceFixtures.PolicyDecisions`. Stop before
`proposed_contact.v1` and merge the new family behind unchanged
`ReferenceFixtures.all/0` and `fetch/1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 9,483 lines.
These two fixtures form one contiguous 88-line policy decision family, and both
keys have focused coverage in `validation/policy_decision_fixture_test.exs`.

Current coupling/problem:
Two related policy fixtures remain embedded in the facade despite shared
approval/decision responsibility and focused test ownership. Neither
references a facade helper attribute, so the pair can move without coupling
the following proposed-contact/candidate-strategy fixture.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.PolicyDecisions`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/policy_decisions.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused policy-decision and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The two policy fixtures exist only in the policy-decision family, all 20
fixture maps have disjoint key sets, `all/0` and `fetch/1` return exactly the
same 195-entry map and deterministic term bytes, focused and full validation
tests pass, and bounded review finds no blocker.

Verification gaps:
- None for this bounded slice.

Tests run:
- Exact post-split proof matched the 195-entry selection baseline,
  deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Source-boundary proof found 2 policy-decision, 2 manifest, 4 core-run, 3
  candidate-strategy, 6 environment, 2 candidate-state, 2 capacity/filter, 2
  filter/rejection, 2 planning-feedback, 4 timeline, 3 readiness, 2 contact, 2
  station-allocation, 2 freshness/budget, 2 base, 3 campaign-planning, 10
  campaign-artifact, 3 accepted-state, 6 orbital, and 133 facade keys with no
  duplicate anchors; facade `fetch/1` matched both moved values.
- Strict test compile passed with warnings as errors.
- Focused policy-decision, core-policy, and facade validation tests: 14 passed.
- Full validation test family: 181 passed.
- Format, tracked/untracked diff hygiene, and xref caller checks passed.
- Bounded read-only review was clean: exactly baseline indices 1-2 moved,
  proposed contact and the full remainder stayed exact, all 20 maps are
  pairwise disjoint, their union equals `103f345f`, fetch edge behavior
  matches, and compile dependencies are one-way.

Behavior/schema changes:
None.

Outcome:
The approval-requirement and policy-decision fixtures now live in
`Validation.ReferenceFixtures.PolicyDecisions`; the facade merges that family
with 19 existing fixture maps plus 133 remaining fixtures. The facade fell
from 9,483 to 9,397 lines, while the extracted family is 96 lines.

Last completed slice:
Manifest fixture extraction published as `dbe4437e`: the two exact
field-reference/lint fixtures moved behind the unchanged facade, approval
requirements and the remainder stayed exact, the 195-entry map and
deterministic bytes stayed exact, 181 validation tests passed, and bounded
review was clean.

Next candidate:
After this boundary, decide whether proposed-contact belongs with the existing
candidate-strategy family or should remain until a broader candidate input
family is mapped; do not move it by adjacency alone.

Blocked:
No.
