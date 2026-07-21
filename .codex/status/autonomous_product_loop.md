# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Unify `target_commitment` as a target-observation alias across direct
CandidateRefresh, source-report replay, and V3 mission/objective pressure.

Status:
Implemented and verified; publish pending.

Why this slice:
The live checkout has a semantic split for the campaign V1
`target_commitment` row, whose requirement is one observation of a target. V3
mission normalization and V3 objective-satisfaction pressure correctly map it
to `target_observation`, but CandidateRefresh source-objective replay maps the
same row to `target_revisit`, and direct CandidateRefresh ignores the label.
Equivalent current-mission evidence can therefore produce a revisit decision,
an observation decision, or no decision depending on ingress.

Level 6 pillar:
Refreshed candidates from current mission state plus stable, interoperable
operational artifacts whose equivalent inputs have equivalent semantics.

Behavior/evidence added:
- Added `TargetObservationObjectiveType` as the shared two-label contract for
  `target_observation` and `target_commitment`.
- Direct CandidateRefresh now applies either label to real observation-candidate
  required counts and score terms while retaining the supplied label in audit
  fields.
- CandidateRefresh objective-satisfaction replay now emits canonical
  `target_observation` objectives instead of incorrectly creating
  `target_revisit` demand; its internal count field is the semantically neutral
  `required_observations`.
- Mission normalization, V3 objective-satisfaction pressure, and objective-gap
  classification delegate observation aliasing to the same contract.
- Provider-style `Target Commitment` mission objectives now produce canonical
  target-observation branches and `target_observation_candidate_inserted`
  repair reasons; target-revisit behavior remains separate.
- Capability and V3 artifact docs now state the cross-ingress guarantee.

Verification:
- Focused direct/source/V3/objective-gap suites: 54 passed.
- All test files mentioning target commitment/observation/revisit: 254 passed.
- Full `mix test --timeout 180000`: 3,483 passed after parent-review cleanup.
- Schema lint: 155 artifacts, zero errors/warnings.
- `mix compile --warnings-as-errors`, `mix format --check-formatted`, and
  `git diff --check`: pass.

Parent review:
Complete. The parent inspected the shared contract, every classifier and
canonicalizer, direct candidate scoring, standalone source replay, V3 mission
and source-report branches, repair semantics, summary membership, docs, and
regression coverage. Review found one residual internal `required_revisits`
key on generic source target objectives; it was corrected to
`required_observations` and both the 254-test target sweep and 3,483-test full
suite passed afterward. No must-fix findings remain. Runtime policy disallows
subagent delegation, so the parent performed review and publish prep.

Previous published slice:
- `d81335dd` Expand collection latency provider aliases (`3480 passed`).

Current publish:
- Commit pending.

Remaining maturity gaps:
- Continue calibrated realized-feedback depth and challenge fixtures.
- Continue deeper numerical/backend and resource-model maturity separately.

Blocked:
Not blocked. Runtime policy disallows subagent delegation, so the parent will
perform bounded review and publish handoff.
