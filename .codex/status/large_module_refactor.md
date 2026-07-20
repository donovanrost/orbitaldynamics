# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema candidate-rejection validation context extraction.

Status:
Selected; implementation not started.

Selected boundary:
Add default-context arity-three entry points to CandidateRejectionValidation
for required report and optional report validation. Derive model limits and
required fields from the existing candidate-rejection JSON Schema and registry
owners, route one eager and two lazy Schema consumers directly, and remove both
facade wrappers. Keep the existing customizable arity-four/arity-five APIs.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,860 lines; the other
  targeted public facades are now 164 to 524 lines.
- Both facade wrappers supply only candidate-rejection-owned context: report
  model limits and the registry contract's required fields.
- Exact usage finds one eager required-report pipeline and two optional-report
  callback entries.
- `PlanChangeRegistryContracts` is the existing owner of the candidate
  rejection registry contract; no recursive Schema lookup is required.
- Owner-default entry points preserve the customizable APIs for callers that
  supply alternate limits or required fields.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema timeline-transition validation context extraction, selected in
`0f55f0bb` and implemented in `f1a0f77f`.
`schema.ex` moved from 5,913 to 5,860 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.
