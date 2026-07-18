# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline candidate-rejection derived-reason policy extraction.

Status:
Implemented, verified, independently reviewed, committed, and pushed.

Completed boundary:
Moved the derived candidate-rejection reason pipeline and its two
`maybe_add_reason/3` clauses into the 78-line
`Timeline.CandidateRejectionDerivedReasonPolicy`. The policy calls existing
station, condition, and boolean policies directly. The now 6,000-line Timeline
retains one private derived-reason facade, removes ten redundant classifier
facades, and retains the unrelated activity-precondition normalization facade.

Published commits:
Selected in `082c5ac9` and implemented in `631d8f84`.

Verification:
- Strict warnings-as-errors compile passed across 3,786 files.
- Three focused candidate-rejection examples passed before and after extraction.
- Full Timeline suite passed with 127 examples; Timeline schema-contract suites
  passed with 36 examples.
- Canonical AST equivalence passed for the pipeline and both prepend clauses
  after normalizing only the coordinator name and public/private definition kind.
- Format, diff, whitespace, exactly-one-facade, redundant-facade-removal,
  unchanged Timeline public-definition, sole-production-consumer,
  callback-wiring, and xref checks passed.
- Independent read-only review found no production-code issues and confirmed
  exact pipeline order, reason strings, explicit-false checks, margin field
  order, prepend semantics, adapter routing, outer final sort, and normalization
  callback preservation.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline candidate-rejection derived-reason policy extraction, selected in
`082c5ac9` and implemented in `631d8f84`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
