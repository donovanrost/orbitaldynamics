# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline grouped timeline-ID policy completion.

Status:
Completed and published.

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
- Focused baseline passed 3 summary tests.
- Strict warnings-as-errors compile passed 3,803 modules.
- Focused diff, lifecycle-state, and transition-application summary tests passed
  3 tests.
- Full Timeline suite passed 127 tests.
- Four Timeline schema-contract suites passed 36 tests.
- AST conservation proved both grouping algorithms moved exactly after
  normalizing only the sorted-ID callback invocation.
- Static checks confirmed the facade retains two thin wrappers, the policy owns
  exactly one implementation of each grouping algorithm, public def count
  remains 101, formatting/diff checks pass, and no temporary checker remains.
- Compile-connected xref remained narrow: Timeline has only the pre-existing
  compile edge to `CandidateRejectionStationPolicy`.
- Bounded local review found no correctness or maintainability issues and
  confirmed predicate filtering, nil/empty rejection, map-key sorting, and
  deterministic unique timeline-ID ordering are unchanged.
- Timeline decreased from 5,046 to 5,023 lines; `IdentityGroupingPolicy`
  increased from 24 to 65 lines.

Behavior/schema changes:
None intended. Group filtering, map-key ordering, ID ordering, summary fields,
capabilities, and schema exports should remain byte-for-byte stable.

Last completed slice:
Timeline grouped timeline-ID policy completion, selected in `754829e3` and
implemented in `68aea844`.

Next candidate:
Continue remapping the reduced Timeline facade after generic identity grouping
ownership is complete.

Blocked:
No.
