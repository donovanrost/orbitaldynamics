# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-intent validation context extraction.

Status:
Completed and pushed.

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
Added `ContactIntentValidation` as the registry-backed family owner for the two
selected artifacts and routed their direct `Schema` validation clauses through
it. `schema.ex` moved from 4,829 to 4,826 lines.

Verification:
- Strict focused baseline: 43 tests passed.
- Focused plus adjacent communications, validation, operator-review,
  campaign-planner, candidate-refresh replay, source-report, and export
  coverage after extraction: 56 tests passed.
- Full schema export completed with no checked-in artifact changes.
- Static routing review found exactly the two intended direct facade routes.
- `mix xref trace` confirmed both runtime calls originate in `schema.ex`; a
  bounded production search found no other owner callers.
- Formatting and `git diff --check` passed.
- Strict forced compile passed across 4,085 files with warnings as errors.
- Bounded diff review confirmed registry-owned requirements, contract routing,
  validation ordering, validation paths, and the proposed-contact exclusion
  remain unchanged.
- Implementation committed and pushed as `a60283db`.

Behavior/schema changes:
None. Required fields, validation ordering and paths, public `Schema` APIs,
validation results, and checked-in exports remain unchanged.

Last completed slice:
Schema contact-intent validation context extraction, selected in `8d5283b2`
and implemented in `a60283db`.
`schema.ex` moved from 4,829 to 4,826 lines.

Next candidate:
Re-rank the remaining Schema responsibility clusters and select the next
facade-preserving extraction.

Blocked:
No.
