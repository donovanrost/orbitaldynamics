# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema resource planning/filter owner routing extraction.

Status:
Completed and pushed.

Selected boundary:
Add a registry-backed `ResourceValidation.validate_artifact/4` entry point for
resource projection report/flow summary and resource filter report/summary.
Derive requirements from `ResourceProjectionRegistryContracts` and
`ResourceFilterRegistryContracts`, route all four direct `Schema` clauses, and
preserve every existing `ResourceValidation` API.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,817 lines; the other
  targeted public facades are now 164 to 524 lines.
- The four clauses repeat required-field setup and form the exact two registry
  families already operationally owned by `ResourceValidation`.
- The owner already owns projection model limits and every nested projection
  and filter callback.
- Filter-summary model limits are available directly from
  `ResourceFilterCapabilityContext`; no facade-only context is required.
- No route needs recursive `Schema` lookup.

Implementation:
Added a registry-backed `ResourceValidation.validate_artifact/4` entry point,
moved the filter-summary default model-limit and callback wiring into the
existing owner, and routed the four selected direct `Schema` clauses through
it. `schema.ex` moved from 4,817 to 4,803 lines.

Verification:
- Strict focused baseline: 104 tests passed.
- Focused plus adjacent resource, validation, operator-review,
  campaign-planner, candidate-refresh replay, contract, and export coverage
  after extraction: 128 tests passed.
- Full schema export completed with no checked-in artifact changes.
- Static routing review found exactly the four intended direct facade routes.
- `mix xref trace` confirmed all four runtime calls originate in `schema.ex`; a
  bounded production search found no other `validate_artifact/4` callers.
- Formatting and `git diff --check` passed.
- Strict forced compile passed across 4,086 files with warnings as errors.
- Bounded diff review confirmed registry-owned requirements, owner-default
  projection/filter model limits and callbacks, contract routing, validation
  ordering, and paths remain unchanged.
- Implementation committed and pushed as `98e0f95a`.

Behavior/schema changes:
None. Required fields, validation ordering and paths, public `Schema` and
existing `ResourceValidation` APIs, validation results, and checked-in exports
remain unchanged.

Last completed slice:
Schema resource planning/filter owner routing extraction, selected in
`63dde824` and implemented in `98e0f95a`.
`schema.ex` moved from 4,817 to 4,803 lines.

Next candidate:
Re-rank the remaining Schema responsibility clusters and select the next
facade-preserving extraction.

Blocked:
No.
