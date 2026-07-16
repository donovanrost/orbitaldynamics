# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh contact-intent context extraction.

Status:
Selected; implementation pending.

Selected slice:
Extract the complete contact-intent source-report validator and its exclusive
stable-ID map helper behind the existing public context function, while reusing
the already extracted direction-routing owner.

Why this slice:
The context and stable-ID helper form one cohesive capacity/routing validation
responsibility with six focused replay/build suites. The routing module remains
shared with the public `/5` routing facade.

Public facade to preserve:
`validate_contact_intent_context/4` and the existing
`validate_contact_intent_direction_routing/5`, including their callback-list
guards, plus all other public signatures.

Likely extraction target:
`CandidateRefreshContactIntentContracts.validate/3`, owning the full context
flow and stable-ID map helper while delegating routing to
`CandidateRefreshContactIntentRoutingContracts`.

Likely files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_contact_intent_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- contact-intent replay/candidate-source/routing/review-import/build tests
- candidate-refresh resource-provenance and schema contract coverage
- broader candidate-refresh, deterministic export/fingerprint, xref, and format

Definition of done:
The public context `/4` function is a thin delegate, the `/5` routing facade is
unchanged, the exclusive stable-ID helper moves without duplication, all order/
paths/errors remain unchanged, and focused/broader checks pass.

Verification gaps:
- Full repository suite not run.

Last commit:
Published quality-gate extraction `b048b7bf`.

Blocked:
No.
