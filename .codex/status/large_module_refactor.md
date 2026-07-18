# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity relationship context extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Move dependency/exclusivity context construction and its eight relationship
policy adapters into one dedicated module. Keep the existing private Timeline
facades for coordinator consumers, pass the stable-ID pattern explicitly, and
route field selection, ID normalization/duplicate detection, overlap
normalization, and compaction directly through existing policies.

Selection evidence:
- The boundary owns normalized and duplicate dependency/exclusivity activity
  and timeline IDs plus allow-overlap evidence.
- The context builder has two consumers: activity precondition summaries and
  valid activity-context assembly.
- The eight relationship values also serve integrity, row, precondition, and
  diff workflows through existing private Timeline facades.
- Passing the stable-ID pattern explicitly preserves one validation
  configuration owner.
- Direct existing policies satisfy the boundary without Timeline callbacks.
- The extraction should materially reduce the current 5,390-line Timeline while
  preserving coordinator seams.
- Relationship policy logic, integrity annotation, scheduling decisions, broad
  context coordination, public API, and schema remain outside the boundary.

Verification:
Pending: focused baseline, implementation, strict compile, focused/full tests,
contracts, structural/static checks, and independent review.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity lifecycle context extraction, selected in `a05a86dd` and
implemented in `55d76306`.

Next candidate:
Continue remapping the reduced Timeline facade.

Blocked:
No.
