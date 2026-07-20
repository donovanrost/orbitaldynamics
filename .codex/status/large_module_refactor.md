# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema resource planning/filter owner routing extraction.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, validation ordering and paths, public `Schema`
and existing `ResourceValidation` APIs, validation results, and checked-in
exports must remain unchanged.

Last completed slice:
Schema approval-policy owner routing extraction, selected in `67647dcc` and
implemented in `34877d2c`.
`schema.ex` moved from 4,823 to 4,817 lines.

Next candidate:
Implement and verify the selected resource owner routing, then re-rank the
remaining Schema responsibility clusters.

Blocked:
No.
