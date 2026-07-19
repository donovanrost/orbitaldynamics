# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport V3 strategy artifact orchestration extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract the V3 strategy artifact constructor orchestration into
`OrbitalDynamics.CadenceImport.StrategyArtifactImport`. Preserve
`from_strategy_artifact/2` as the public facade and pass its existing strategy
row, review-row, feedback-context, and manifest-builder seams as callbacks.

Selection evidence:
- `cadence_import.ex` is now 2,170 lines.
- The selected constructor spans about 65 lines and coordinates branch
  ordering, strategy/review row composition, provenance, and manifest context.
- Its responsibility is orchestration; concrete row builders, review dispatch,
  feedback context construction, and manifest assembly already have separate
  owners and remain behind callbacks.
- Public API docs, V1 campaign construction, schemas, and candidate/repair
  review-package imports remain outside the boundary.

Verification:
Pending: focused strategy baselines, exact old/new constructor equivalence
proof, strict compile, all combined CadenceImport tests, schema contracts,
static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport campaign review-package import extraction, selected in
`072075ce` and implemented in `e761b39b`. `cadence_import.ex` moved from 2,193
to 2,170 lines; the extracted owner is 46 lines.

Next candidate:
Re-inventory V1 campaign construction or manifest routing after V3 strategy
orchestration has one production owner.

Blocked:
No.
