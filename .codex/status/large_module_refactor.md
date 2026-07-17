# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Proposed-contact fixture ownership cleanup.

Status:
Publishing.

Selected slice:
Move the now-first `proposed_contact.v1` fixture from the facade into the
existing `Validation.ReferenceFixtures.CandidateStrategyArtifacts` leaf. Stop
before `policy_bundle.v1`; do not create another leaf module.

Why this slice:
`ReferenceFixtures` remains the largest production module at 9,397 lines.
The 44-line fixture shares candidate-strategy responsibility and dedicated
coverage with the three fixtures already in `CandidateStrategyArtifacts`.

Current coupling/problem:
One candidate-strategy fixture remains in the facade solely because it was
previously separated from its test-owned family. It references no facade helper
attribute, and creating a one-fixture module would fragment ownership.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.CandidateStrategyArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/candidate_strategy_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused candidate-strategy and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The proposed-contact fixture exists only in the candidate-strategy leaf, all 20
fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the
same 195-entry map and deterministic term bytes, focused and full validation
tests pass, and bounded review finds no blocker.

Verification gaps:
- None for this bounded slice.

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
The exact proposed-contact fixture now lives with the existing candidate
strategy artifact family. The public facade remains unchanged and shrank from
9,397 to 9,353 lines; the cohesive leaf grew from three to four fixtures and
from 241 to 285 lines without adding another module.

Last completed slice:
Policy-decision fixture extraction published as `aeb1b10b`: the two exact
approval/decision fixtures moved behind the unchanged facade, proposed contact
and the remainder stayed exact, the 195-entry map and deterministic bytes
stayed exact, 181 validation tests passed, and bounded review was clean.

Next candidate:
After this boundary, map the policy-bundle fixture range by focused policy
bundle tests and choose bounded subfamilies rather than moving all variants at
once.

Blocked:
No.
