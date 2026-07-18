# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline candidate-rejection summary policy extraction.

Status:
Implemented, verified, independently reviewed, committed, and pushed.

Completed boundary:
Moved candidate-rejection reason frequencies, predicate-selected candidate IDs,
candidate IDs grouped by rejection reason, candidate IDs grouped by required
operator action, and their deterministic nil-rejecting sort/unique helper into
the 42-line `Timeline.CandidateRejectionSummaryPolicy`. The 6,170-line Timeline
retains four thin private facades; report coordination and public API are
unchanged.

Published commits:
Selected in `5449e522` and implemented in `63a5d72c`.

Verification:
- Strict warnings-as-errors compile passed across 3,783 files.
- Three focused mixed-summary, nested-capacity, and nested-availability
  candidate-rejection examples passed before and after extraction.
- Full Timeline suite passed with 127 examples; Timeline schema-contract suites
  passed with 36 examples.
- Canonical AST equivalence passed for all five moved definitions after
  normalizing only public/private definition kind.
- Format, diff, whitespace, exactly-four-facade, exactly-four-policy-entry-point,
  unchanged Timeline public-definition, and sole-runtime-caller checks passed.
- Independent read-only review found no production-code issues and confirmed
  exact frequency, predicate, missing-key, grouping, nil-rejection, uniqueness,
  sorting, and nil-group-key behavior.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline candidate-rejection summary policy extraction, selected in `5449e522`
and implemented in `63a5d72c`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
