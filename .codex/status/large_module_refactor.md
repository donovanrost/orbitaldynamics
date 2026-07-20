# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema candidate-activity owner completion.

Status:
Complete and pushed.

Selected boundary:
Extend `StateRefreshArtifactValidation.validate/4` to own
`candidate_activity.v1`, whose registry is already included in that owner.
Route the direct `Schema` clause through the existing state-refresh owner while
preserving required-field setup followed by `CandidateActivityContracts`.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,730 lines; the other
  targeted public facades are now 164 to 524 lines.
- The direct clause repeats the same generic registered-artifact routing pattern
  already owned for the surrounding candidate-refresh artifact family.
- `StateRefreshArtifactValidation` already merges
  `CandidateRefreshRegistryContracts`, including `candidate_activity.v1`.
- No route needs recursive `Schema` lookup.

Implementation:
Extended `StateRefreshArtifactValidation.validate/4` with the
`candidate_activity.v1` contract route, then routed the direct `Schema` clause
through the existing state-refresh owner. `schema.ex` moved from 4,730 to 4,728
lines; `StateRefreshArtifactValidation` moved from 109 to 112 lines.

Verification:
- Strict focused baseline: 27 tests passed.
- Candidate-refresh registry, accepted-state, build, export, and fixture
  adjacency: 37 tests passed.
- Full schema export regenerated with no checked-in schema artifact changes.
- Formatting, diff whitespace, bounded dependency/reference checks, and the
  bounded semantic diff review passed.
- `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force
  --warnings-as-errors` compiled 4,087 files successfully.

Behavior/schema changes:
None. Required fields, validation ordering and paths, public `Schema` and
`StateRefreshArtifactValidation` APIs, validation results, and checked-in
exports remain unchanged.

Last completed slice:
Schema candidate-activity owner completion, selected in `313e38cf` and
implemented in `23cf1b4e`. `schema.ex` moved from 4,730 to 4,728 lines.

Next candidate:
Re-rank the remaining direct `Schema` validation clauses, prioritizing a
cohesive owner or owner completion without recursive `Schema` lookup or public
API changes.

Blocked:
No.
