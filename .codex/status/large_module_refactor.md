# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema accepted-state/candidate-refresh validation context extraction.

Status:
Completed and pushed.

Selected boundary:
Add StateRefreshArtifactValidation owner-default entry points for three
accepted-state artifacts and eight candidate-refresh/diff/window artifacts.
Derive requirements from the accepted-state and candidate-refresh registries,
compose the candidate-refresh report callbacks from existing owners, and route
all 11 direct Schema clauses. Keep artifact contract APIs unchanged.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,939 lines; the other
  targeted public facades are now 164 to 524 lines.
- Eleven adjacent direct clauses repeat registry requirements and owner routing.
- AcceptedStateRegistryContracts and CandidateRefreshRegistryContracts own
  every required-field definition.
- CandidateRefreshContracts needs only existing contact-allocation and
  candidate-rejection owner callbacks.
- Accepted-state, candidate-diff, freshness, budget, and window contract modules
  own all remaining artifact-specific validation.
- No route needs recursive Schema lookup or facade-local callbacks.

Implementation:
Added StateRefreshArtifactValidation with one two-registry-backed entry point,
accepted-state required-field ownership, candidate-refresh callback context,
and nine require-first state/diff/freshness/budget/window routes. Routed all 11
direct Schema clauses to the owner. `schema.ex` moved from 4,939 to 4,889 lines.

Verification:
- Strict accepted-state/candidate-refresh baseline before extraction: 17
  passed.
- The same strict focused suite after extraction: 17 passed.
- Strict candidate-diff, freshness, refresh-budget, and state-fixture coverage:
  39 passed.
- The full schema-export task completed and produced no checked-in changes.
- Exact static inspection confirms 11 direct owner routes and no remaining
  facade-local accepted-state/candidate-refresh validation logic.
- `mix xref callers OrbitalDynamics.Schema.StateRefreshArtifactValidation`
  reports only the expected Schema facade runtime caller.
- `mix format --check-formatted` and `git diff --check` passed.
- Strict forced compile passed across 4,078 files with no warnings.
- Bounded local review confirmed registry requirements, callback order,
  require-first and explicit schema-contract checks, issue paths, and the
  candidate-refresh path-independent contract API are preserved.
- Implementation commit `3411b55c` pushed to `main`.

Behavior/schema changes:
None. Required fields, callbacks, validation ordering and paths, public Schema
APIs, validation results, and checked-in exports remain unchanged.

Last completed slice:
Schema accepted-state/candidate-refresh validation context extraction, selected
in `139671e3` and implemented in `3411b55c`.
`schema.ex` moved from 4,939 to 4,889 lines.

Next candidate:
Re-rank the remaining Schema responsibility clusters. Preserve the
context-bearing CommonJsonSchema wrappers unless a separate exact ownership
boundary is proven.

Blocked:
No.
