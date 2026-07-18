# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity relationship context extraction.

Status:
Complete and published.

Selected boundary:
Move dependency/exclusivity context construction and its eight relationship
policy adapters into one dedicated module. Keep the existing private Timeline
facades for coordinator consumers, pass the stable-ID pattern explicitly, and
route field selection, ID normalization/duplicate detection, overlap
normalization, and compaction directly through existing policies. Remove the
shared duplicate scalar, normalized map, and duplicate map ID Timeline facades
because strict compile confirmed the moved adapters owned their only remaining
callers.

Selection evidence:
- The boundary owns normalized and duplicate dependency/exclusivity activity
  and timeline IDs plus allow-overlap evidence.
- The context builder has two consumers: activity precondition summaries and
  valid activity-context assembly.
- The eight relationship values also serve integrity, row, precondition, and
  diff workflows through existing private Timeline facades.
- Passing the stable-ID pattern explicitly preserves one validation
  configuration owner.
- The initial strict compile proved `duplicate_id_list/2`,
  `normalize_map_id_list/2`, and `duplicate_map_id_list/2` became unused after
  the move; repo search confirmed no other Timeline callers. The shared scalar
  `normalize_id_list/2` remains used by other boundaries.
- Direct existing policies satisfy the boundary without Timeline callbacks.
- The extraction should materially reduce the current 5,390-line Timeline while
  preserving coordinator seams.
- Relationship policy logic, integrity annotation, scheduling decisions, broad
  context coordination, public API, and schema remain outside the boundary.

Verification:
- Selection published in `7a910e0c`; corrected helper ownership published in
  `af7fcfff`; implementation published in `2c33add2`.
- Focused baseline and post-change relationship coverage: 3 passed.
- Strict warnings-as-errors compile: 3,799 files compiled.
- Full Timeline suite: 127 passed.
- Operational Timeline schema contracts: 36 passed.
- Canonical AST comparison: the builder and all eight adapters equivalent after
  normalizing only the explicit stable-pattern boundary and callback captures.
- Static checks confirmed unchanged public API, exact context/value facade
  consumer counts, removal of three dead ID helpers while retaining the shared
  scalar normalizer, Timeline-only runtime ownership, no temporary checker, and
  clean formatting/diff.
- Independent review: clean, with no production-code findings.
- Timeline is 5,343 lines; the extracted module is 138 lines.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity relationship context extraction, selected in `7a910e0c`,
corrected in `af7fcfff`, and implemented in `2c33add2`.

Next candidate:
Continue remapping the reduced Timeline facade.

Blocked:
No.
