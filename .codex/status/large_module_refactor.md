# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline grouped timeline-ID policy completion.

Status:
Selected; implementation has not started.

Selected boundary:
Move the two grouped timeline-ID aggregation bodies from the Timeline facade
into the existing `IdentityGroupingPolicy`. Keep the facade wrappers and pass
the existing `sorted_uniq/1` behavior explicitly.

Selection evidence:
- `timeline_ids_by/3` and `timeline_ids_by_each/3` are generic identity-grouping
  algorithms used by diff, lifecycle-state, and transition-application
  summaries; they belong with the existing identity grouping helpers.
- The facade wrappers preserve all current call sites while the policy receives
  the existing deterministic sorted-ID callback.
- Three focused tests cover scalar-key grouping, multi-key grouping, empty-key
  rejection, unique sorting, lifecycle review routing, and transition
  application summary routing.
- Timeline is 5,046 lines; `IdentityGroupingPolicy` is 24 lines.
- Public Timeline APIs, summary maps, callback predicates/key functions,
  schema/model ownership, capability values, generated exports, and other
  aggregation responsibilities remain outside the boundary.

Verification:
Pending: focused baselines, mechanical policy move, strict compile, focused and
full Timeline tests, schema contracts, structural/static checks, and bounded
review.

Behavior/schema changes:
None intended. Group filtering, map-key ordering, ID ordering, summary fields,
capabilities, and schema exports should remain byte-for-byte stable.

Last completed slice:
Timeline lifecycle-state summary row policy extraction, selected in `c813f233`
and implemented in `6fa5b2bd`.

Next candidate:
Continue remapping the reduced Timeline facade after generic identity grouping
ownership is complete.

Blocked:
No.
