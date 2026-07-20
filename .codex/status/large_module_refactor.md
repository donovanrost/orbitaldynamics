# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema candidate-rejection validation context extraction.

Status:
Completed and pushed.

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
Added default-context arity-three report and optional-report entry points to
CandidateRejectionValidation, kept the customizable arity-four/arity-five
APIs, derived context from the existing candidate-rejection schema and registry
owners, routed one eager and two lazy facade consumers directly, and removed
both wrappers. `schema.ex` moved from 5,860 to 5,841 lines.

Verification:
- Strict candidate-rejection/campaign/Cadence/operator-review baseline before
  extraction: 9 passed.
- The same strict focused suite after extraction: 9 passed.
- Strict checked-in export, review/import handoff, and JSON Schema export
  coverage: 22 passed.
- The full schema-export task completed and produced no checked-in changes.
- Exact static inspection confirms one direct eager validation, two direct
  lazy callbacks, zero facade wrappers, and retained customizable owner APIs.
- `mix xref callers OrbitalDynamics.Schema.CandidateRejectionValidation`
  reports only the expected Schema facade runtime caller.
- `mix format --check-formatted` and `git diff --check` passed.
- Strict forced compile passed across 4,072 files with no warnings.
- Bounded local diff review found no must-fix findings.
- Implementation commit `ef9b3d23` pushed to `main`.

Behavior/schema changes:
None. Required fields, model limits, issue ordering and paths, customizable
owner entry points, public Schema APIs, validation results, and checked-in
exports remain unchanged.

Last completed slice:
Schema candidate-rejection validation context extraction, selected in
`41574844` and implemented in `ef9b3d23`.
`schema.ex` moved from 5,860 to 5,841 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.
