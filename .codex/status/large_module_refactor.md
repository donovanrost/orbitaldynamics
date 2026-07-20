# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema relay data-path owner completion.

Status:
Complete and pushed.

Selected boundary:
Extend `LinkCapacityValidation` to own registry-backed validation for
`relay_data_path_summary.v1`. Route the direct `Schema` clause through the
ground-network capacity owner while preserving required-field setup followed
by `RelayDataPathSummaryContracts.validate_summary/3`.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,728 lines; the other
  targeted public facades are now 164 to 524 lines.
- The relay summary is produced from link-capacity/contact routing evidence and
  is adjacent to the existing link-capacity report/summary owner.
- `RelayDataPathRegistryContracts` and `RelayDataPathSummaryContracts` already
  provide the exact setup and validator.
- No route needs recursive `Schema` lookup.

Implementation:
Extended `LinkCapacityValidation` with registry-backed
`validate_relay_data_path_summary/3`, then routed the direct `Schema` clause
through the ground-network capacity owner. `schema.ex` moved from 4,728 to
4,726 lines; `LinkCapacityValidation` moved from 33 to 45 lines.

Verification:
- Strict focused baseline: 50 tests passed.
- Complete link-capacity producer, replay, planner, review, import, export, and
  fixture family: 91 tests passed.
- Full schema export regenerated with no checked-in schema artifact changes.
- Formatting, diff whitespace, bounded dependency/reference checks, and the
  bounded semantic diff review passed.
- `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force
  --warnings-as-errors` compiled 4,087 files successfully.

Behavior/schema changes:
None. Required fields, validation ordering and paths, public `Schema` and
existing `LinkCapacityValidation` APIs, validation results, and checked-in
exports remain unchanged.

Last completed slice:
Schema relay data-path owner completion, selected in `30581147` and implemented
in `85701edc`. `schema.ex` moved from 4,728 to 4,726 lines.

Next candidate:
Re-rank the remaining direct `Schema` validation clauses, prioritizing a
cohesive owner or owner completion without recursive `Schema` lookup or public
API changes.

Blocked:
No.
