# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Proposed-contact fixture ownership cleanup.

Status:
Ready for implementation.

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
- Implementation and verification pending.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

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
