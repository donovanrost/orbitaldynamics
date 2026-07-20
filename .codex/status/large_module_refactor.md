# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema resource-summary owner completion.

Status:
Complete and pushed.

Selected boundary:
Extend `ResourceValidation.validate_artifact/4` and its registry lookup to own
`resource_summary.v1`. Route the direct `Schema` clause through the existing
resource owner while preserving its current required-field pass followed by
the existing summary-contract validation.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,732 lines; the other
  targeted public facades are now 164 to 524 lines.
- The direct clause repeats the same registered-artifact routing pattern already
  owned by `ResourceValidation` for projection and filter artifacts.
- `ResourceSummaryRegistryContracts` and `ResourceSummaryContracts` already
  provide the required fields and exact validator.
- No route needs recursive `Schema` lookup.

Implementation:
Extended `ResourceValidation.validate_artifact/4` with the
`resource_summary.v1` registry and contract route, then routed the direct
`Schema` clause through the existing resource owner. `schema.ex` moved from
4,732 to 4,730 lines; `ResourceValidation` moved from 214 to 218 lines.

Verification:
- Strict focused baseline: 27 tests passed.
- Resource summary, projection, filter, export, and fixture adjacency: 118 tests
  passed.
- Full schema export regenerated with no checked-in schema artifact changes.
- Formatting, diff whitespace, bounded dependency/reference checks, and the
  bounded semantic diff review passed.
- `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force
  --warnings-as-errors` compiled 4,087 files successfully.

Behavior/schema changes:
None. Required fields, duplicate required-field issue behavior, validation
ordering and paths, public `Schema` and `ResourceValidation` APIs, validation
results, and checked-in exports remain unchanged.

Last completed slice:
Schema resource-summary owner completion, selected in `427ca19f` and implemented
in `7778c944`. `schema.ex` moved from 4,732 to 4,730 lines.

Next candidate:
Re-rank the remaining direct `Schema` validation clauses, prioritizing a
cohesive owner or owner completion without recursive `Schema` lookup or public
API changes.

Blocked:
No.
