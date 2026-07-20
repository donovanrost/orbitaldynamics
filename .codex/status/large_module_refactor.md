# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema realized-state validation context extraction.

Status:
Completed and pushed.

Selected boundary:
Add `RealizedStateValidation` owner-default entry points for
`realized_activity.v1` and `realized_state_snapshot.v1`. Derive requirements
from `RealizedStateRegistryContracts`, route both direct `Schema` clauses, and
keep both artifact-specific contract APIs unchanged.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,826 lines; the other
  targeted public facades are now 164 to 524 lines.
- The two adjacent clauses repeat required-field setup and form the exact family
  owned by `RealizedStateRegistryContracts`.
- `RealizedActivityContracts` and `RealizedStateSnapshotContracts` own all
  artifact-specific validation.
- Neither route needs callbacks, recursive `Schema` lookup, model limits, or
  facade-local context.

Implementation:
Added `RealizedStateValidation` as the registry-backed family owner for the two
selected artifacts and routed their direct `Schema` validation clauses through
it. `schema.ex` moved from 4,826 to 4,823 lines.

Verification:
- Strict focused baseline: 94 tests passed.
- Focused plus adjacent realized-state, operator-review, Cadence import,
  validation, timeline-feedback, candidate-refresh, campaign-planner, contract,
  and export coverage after extraction: 113 tests passed.
- Full schema export completed with no checked-in artifact changes.
- Static routing review found exactly the two intended direct facade routes.
- `mix xref trace` confirmed both runtime calls originate in `schema.ex`; a
  bounded production search found no other owner callers.
- Formatting and `git diff --check` passed.
- Strict forced compile passed across 4,086 files with warnings as errors.
- Bounded diff review confirmed registry-owned requirements, contract routing,
  validation ordering, and validation paths remain unchanged.
- Implementation committed and pushed as `7afa123b`.

Behavior/schema changes:
None. Required fields, validation ordering and paths, public `Schema` APIs,
validation results, and checked-in exports remain unchanged.

Last completed slice:
Schema realized-state validation context extraction, selected in `121d60c9`
and implemented in `7afa123b`.
`schema.ex` moved from 4,826 to 4,823 lines.

Next candidate:
Re-rank the remaining Schema responsibility clusters and select the next
facade-preserving extraction.

Blocked:
No.
