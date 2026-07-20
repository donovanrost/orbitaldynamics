# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-intent validation context extraction.

Status:
Selected; implementation pending.

Selected boundary:
Add `ContactIntentValidation` owner-default entry points for
`contact_intent.v1` and `contact_intent_summary.v1`. Derive requirements from
`ContactIntentRegistryContracts`, route both direct `Schema` clauses, and keep
both artifact-specific contract APIs unchanged.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,829 lines; the other
  targeted public facades are now 164 to 524 lines.
- The two adjacent clauses repeat required-field setup and form the exact family
  owned by `ContactIntentRegistryContracts`.
- `ContactIntentContracts` and `ContactIntentSummaryContracts` own all
  artifact-specific validation.
- Neither route needs callbacks, recursive `Schema` lookup, model limits, or
  facade-local context.
- `proposed_contact.v1` remains out of scope because it belongs to the distinct
  `ProposedContactRegistryContracts` family.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, validation ordering and paths, public `Schema`
APIs, validation results, and checked-in exports must remain unchanged.

Last completed slice:
Schema provider-counteroffer validation context extraction, selected in
`ab187bb8` and implemented in `45176e44`.
`schema.ex` moved from 4,842 to 4,829 lines.

Next candidate:
Implement and verify the selected contact-intent context, then re-rank the
remaining Schema responsibility clusters.

Blocked:
No.
