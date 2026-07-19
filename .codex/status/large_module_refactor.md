# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline application identity collection policy completion.

Status:
Selected; implementation has not started.

Selected boundary:
Move transition-application timeline-ID and activity-ID collection from the
Timeline facade into the existing `IdentityGroupingPolicy`. Keep both facade
wrappers and pass the existing `sorted_uniq/1` behavior explicitly.

Selection evidence:
- The two collectors are used only by transition-application summary fields and
  sit immediately beside the grouped timeline-ID wrappers.
- `IdentityGroupingPolicy` now owns the generic grouped-ID algorithms; filtered
  application identity collection is the same responsibility.
- The facade wrappers preserve all five current call sites while the policy
  receives the existing deterministic sorted-ID callback.
- One focused transition-application summary test covers review, applied,
  preserved, selected, and withheld timeline/activity ID sets and schema
  validation.
- Timeline is 5,023 lines; `IdentityGroupingPolicy` is 65 lines.
- Public Timeline APIs, summary maps, predicate callbacks, schema/model
  ownership, capability values, generated exports, and other aggregation
  responsibilities remain outside the boundary.

Verification:
Pending: focused baseline, mechanical policy move, strict compile, focused and
full Timeline tests, schema contracts, structural/static checks, and bounded
review.

Behavior/schema changes:
None intended. Predicate filtering, nil rejection, ID ordering, summary fields,
capabilities, and schema exports should remain byte-for-byte stable.

Last completed slice:
Timeline grouped timeline-ID policy completion, selected in `754829e3` and
implemented in `68aea844`.

Next candidate:
Continue remapping the reduced Timeline facade after application identity
collection ownership is complete.

Blocked:
No.
